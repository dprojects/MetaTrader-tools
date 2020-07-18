/* -----------------------------------------------------------------------------------------------------------------------

   2020, This tool analyzes SL, TP and Open price slips.

   -------------------------------------------------------------------------------------------------------------------- */

#property copyright "Darek L"
#property link      "https://github.com/dprojects"
#property version   "20.20"
#property strict

#include <stdlib.mqh>
#include <WinUser32.mqh>

// -----------------------------------------------------------------------------------------------------------------------
// SETTINGS
// -----------------------------------------------------------------------------------------------------------------------

bool sHTML     = true;                                                        // generate HTML output
bool sCSV      = true;                                                        // generate CSV output

string sSep    = ";";                                                         // CSV entry separator, for converters
string sCol    = " | ";                                                       // left padding
string sLine   = sCol +
                        "--------------------------------------------------------------------------------" +
                        "--------------------------------------------------------------------------------" +
                        "--------------------------------------------------------------------------------";

// -----------------------------------------------------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------------------------------------------------

// counters - open slip 
double gOSCBH = 0; // Open Slip Closed by Broker with Honest return points
double gOSCBE = 0; // Open Slip Closed by Broker with Earn return points
double gOSCBL = 0; // Open Slip Closed by Broker with Loss return points

double gOSCTE = 0; // Open Slip Closed by Trader with Earn return points
double gOSCTL = 0; // Open Slip Closed by Trader with Loss return points

double gOSA = 0;   // Open Slip All

// counters - close slip
double gBigTPB = 0; // close slip with Bigger Take Profit by Broker (good)
double gCutSLB = 0; // close slip with Cut Stop Loss by Broker (good)

double gCutTPB = 0; // close slip with Cut Take Profit by Broker (bad)
double gBigSLB = 0; // close slip with Bigger Stop Loss by Broker (bad)

// counters - other
double gQuickEarn = 0, gDTEarn = 0, gInvestEarn = 0, gHedgeEarn = 0;
double gQuickLoss = 0, gDTLoss = 0, gInvestLoss = 0, gHedgeLoss = 0;
double gCutTPT = 0, gCutSLT = 0;
double gSLEqual = 0, gTPEqual = 0, gCloseSlip = 0, gBrokerClosed = 0; 
double gSet = 0, gNotSet = 0, gActivated = 0;

// profit
double gOSCBHP = 0, gOSCBEP = 0, gOSCBLP = 0, gOSCBAP = 0;
double gOSCTEP = 0, gOSCTLP = 0, gOSCTAP = 0;
double gOSAP = 0;
double gBigTPBP = 0, gBigSLBP = 0, gCutTPBP = 0, gCutSLBP = 0;
double gQuickEarnP = 0, gDTEarnP = 0, gInvestEarnP = 0, gHedgeEarnP = 0;
double gQuickLossP = 0, gDTLossP = 0, gInvestLossP = 0, gHedgeLossP = 0;
double gCutTPTP = 0, gCutSLTP = 0;
double gSLEqualP = 0, gTPEqualP = 0, gCloseSlipP = 0, gBrokerClosedP = 0; 
double gSetP = 0, gNotSetP = 0, gActivatedP = 0;

// diff points value
double gOSCBEV = 0, gOSCBLV = 0, gOSCBAV = 0;
double gOSCTEV = 0, gOSCTLV = 0, gOSCTAV = 0;
double gOSAV = 0;
double gBigTPBV = 0, gBigSLBV = 0, gCutTPBV = 0, gCutSLBV = 0;

// switches
int    gShow = 0;
bool   gHadOpenFeature = false, gIsOpenFeature = false;

// calculation
double gPoint = 0, gOpenReq = 0, gPointVal = 0, gOSlip = 0, gOSlipAbs = 0;
string gCurrency = AccountCurrency();

// content
string gHTML = "", gHTMLe = "", gHTMLeq = "";
string gCSV = "", gCSVe = "", gCSVeq = "";

// summary
string gIssue = "", gSum = "", gOpenInfo  = "";

// -----------------------------------------------------------------------------------------------------------------------
// Set global variables
// -----------------------------------------------------------------------------------------------------------------------

void setGlobals()
{
   double vProfitPoints = 0;
   string kExt[];
   string k = OrderComment();

   // reset values for each order
   gShow = 0; gIssue = ""; gIsOpenFeature = false;

   // for old markets, need to open chart to load data to get it worked
   gPoint = MarketInfo(OrderSymbol(), MODE_POINT);
   
   // check if there is open feature active in comment
   if (StringFind(k, ":", 0) != -1) { gIsOpenFeature = true; gHadOpenFeature = true; }

   // set open slip
   if (gIsOpenFeature)
   {
      StringSplit(k, StringGetCharacter(":", 0), kExt); 

      gOpenReq = (double)kExt[1];
      gPointVal = (double)kExt[2];

      if (OrderOpenPrice() != gOpenReq)
      {
         if (gPoint != 0)
         { 
            gOSlip = MathRound((OrderOpenPrice() - gOpenReq) / gPoint);
            gOSlipAbs = MathAbs(gOSlip);
         }
      }      
   }
   else
   {
      if (gPoint != 0)
      {
         vProfitPoints = MathRound( MathAbs(OrderClosePrice() - OrderOpenPrice()) / gPoint );
         if (vProfitPoints != 0) { gPointVal = MathAbs(OrderProfit()) / vProfitPoints; }
      }      
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Set final summary
// -----------------------------------------------------------------------------------------------------------------------

void setSummary()
{
   double vRatioG = 0, vRatioA = 0, vCloseSlips = 0, vCloseSlipsP = 0, vCloseSlipsV = 0;
   string vR = "";
   string vDataSep = "$";
   string vEarn = "Earn", vLoss = "Loss";

   // Set open feature description

   gOpenInfo += "This table below shows orders closed by broker with correct TP or SL price. ";
   gOpenInfo += "If there is incorrect TP or SL size, it means there was open price slip and broker ";
   gOpenInfo += "not gaves you slip points back at the end of order. You need to verify the ";
   gOpenInfo += "TP and SL size on your own, if you remember how many points it should be. ";
   gOpenInfo += "If there is not so many points this is natural thing at not very liquid market but ";
   gOpenInfo += "if there are many orders with big difference and nothing with points back at the table above ";
   gOpenInfo += "this may means the broker cheats you or you have totally wrong strategy ";
   gOpenInfo += "(e.g. scalping at not very liquid market maker or index). To see more detailed report ";
   gOpenInfo += "activate feature by adding for each order exact comment format e.g. ";
   gOpenInfo += ":requested_open_price:pointvalue_for_order: to compare with OrderOpenPrice() later.";

   // Calculate final ratio
   if (gHadOpenFeature) 
   {
      vRatioA =    gOSCBH + gOSCBE + gTPEqual + gSLEqual + gOSCBL;
      vRatioG = ( (gOSCBH + gOSCBE + gTPEqual + gSLEqual) / vRatioA ) * 100;

      gOSA  = gOSCBE  + gOSCBL  + gOSCTE  + gOSCTL;
      gOSAP = gOSCBEP + gOSCBLP + gOSCTEP + gOSCTLP;
      gOSAV = gOSCBEV - gOSCBLV + gOSCTEV - gOSCTLV;
   }
   else
   {
      vRatioA =    gBigTPB + gCutSLB + gTPEqual + gSLEqual + gBigSLB + gCutTPB;
      vRatioG = ( (gBigTPB + gCutSLB + gTPEqual + gSLEqual) / vRatioA ) * 100;

      vCloseSlips  = gBigTPB  + gCutSLB  + gBigSLB  + gCutTPB;
      vCloseSlipsP = gBigTPBP + gCutSLBP + gBigSLBP + gCutTPBP;
      vCloseSlipsV = gBigTPBV + gCutSLBV - gBigSLBV - gCutTPBV;
   }

   if (vRatioG == 100) { vR = "DEMO ?"; } 
   else if (vRatioG > 80) { vR = "VERY GOOD"; } 
   else if (vRatioG > 50) { vR = "GOOD"; }
   else if (vRatioG > 20) { vR = "BAD"; }
   else { vR = "VERY BAD"; }

   vR += "   ( " + DoubleToStr(vRatioG, 0) + "% ) ";
 
   // Summary

   gSum += "Final result for Broker: " + vR;
   
   // Table header

   gSum += vDataSep + "";
   gSum += vDataSep + "Orders";
   gSum += vDataSep + "Ratio";
   gSum += vDataSep + "Profit";
   gSum += vDataSep + "Earn & Loss";
   gSum += vDataSep + "Tips";
   gSum += vDataSep + "Description";
      
   // Open feature

   if (gHadOpenFeature) 
   {
      // Open, TP, SL slip

      gSum += vDataSep + "Open Slip Feature :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gOSCBH, 0);
      gSum += vDataSep + DoubleToStr((gOSCBH / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCBHP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(0, 2) + " " + gCurrency;
      gSum += vDataSep + "( honest broker )";
      gSum += vDataSep + "Orders with open slip, closed by broker, with honest return.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gOSCBE, 0);
      gSum += vDataSep + DoubleToStr((gOSCBE / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCBEP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gOSCBEV, 2) + " " + gCurrency;
      gSum += vDataSep + "( generous broker )";
      gSum += vDataSep + "Orders with open slip, closed by broker, with earn.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gOSCBL, 0);
      gSum += vDataSep + DoubleToStr((gOSCBL / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCBLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-" + DoubleToStr(gOSCBLV, 2) + " " + gCurrency;
      gSum += vDataSep + "( bad broker )";
      gSum += vDataSep + "Orders with open slip, closed by broker, with loss.";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gOSCBE + gOSCBL, 0);
      gSum += vDataSep + DoubleToStr(((gOSCBE + gOSCBL) / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCBEP + gOSCBLP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gOSCBEV - gOSCBLV, 2) + " " + gCurrency;
      if      (gOSCBEV - gOSCBLV > 0) { gSum += vDataSep + "( rather good broker )"; } 
      else if (gOSCBEV - gOSCBLV < 0) { gSum += vDataSep + "( rather bad broker )"; }
      else                            { gSum += vDataSep + ""; }
      gSum += vDataSep + "All orders with open slip, closed by broker.";
      
      // separator

      gSum += vDataSep + "&nbsp;";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gOSCTE, 0);
      gSum += vDataSep + DoubleToStr((gOSCTE / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCTEP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gOSCTEV, 2) + " " + gCurrency;
      gSum += vDataSep + "( possible earn )";
      gSum += vDataSep + "Orders with open slip, closed by trader, with possible earn.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gOSCTL, 0);
      gSum += vDataSep + DoubleToStr((gOSCTL / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCTLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-" + DoubleToStr(gOSCTLV, 2) + " " + gCurrency;
      gSum += vDataSep + "( possible loss )";
      gSum += vDataSep + "Orders with open slip, closed by trader, with possible loss.";

      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gOSCTE + gOSCTL, 0);
      gSum += vDataSep + DoubleToStr(((gOSCTE + gOSCTL) / gOSA) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gOSCTEP + gOSCTLP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gOSCTEV - gOSCTLV, 2) + " " + gCurrency;
      gSum += vDataSep + "( requested close price needed )";
      gSum += vDataSep + "All orders with open slip, closed by trader.";
      
      // separator

      gSum += vDataSep + "&nbsp;";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gOSA, 0);
      gSum += vDataSep + "100 %";
      gSum += vDataSep + DoubleToStr(gOSAP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gOSAV, 2) + " " + gCurrency;
      if      (gOSAV > 0) { gSum += vDataSep + "( rather good broker )"; } 
      else if (gOSAV < 0) { gSum += vDataSep + "( rather bad broker )"; }
      else                { gSum += vDataSep + ""; }
      gSum += vDataSep + "All orders with open slip.";
   }
   else
   {
      // Open, TP, SL slip

      gSum += vDataSep + "Open, TP, SL slip :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gBigTPB, 0);
      gSum += vDataSep + DoubleToStr((gBigTPB / vCloseSlips) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gBigTPBP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gBigTPBV, 2) + " " + gCurrency;
      gSum += vDataSep + "( good broker )";
      gSum += vDataSep + "Broker closed order with bigger TP.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gCutSLB, 0);
      gSum += vDataSep + DoubleToStr((gCutSLB / vCloseSlips) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gCutSLBP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(gCutSLBV, 2) + " " + gCurrency;
      gSum += vDataSep + "( good broker )";
      gSum += vDataSep + "Broker closed order with smaller SL.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gBigSLB, 0);
      gSum += vDataSep + DoubleToStr((gBigSLB / vCloseSlips) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gBigSLBP, 2) + " " + gCurrency;
      gSum += vDataSep + "-" + DoubleToStr(gBigSLBV, 2) + " " + gCurrency;
      gSum += vDataSep + "( bad broker )";
      gSum += vDataSep + "Broker closed order with bigger SL.";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gCutTPB, 0);
      gSum += vDataSep + DoubleToStr((gCutTPB / vCloseSlips) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gCutTPBP, 2) + " " + gCurrency;
      gSum += vDataSep + "-" + DoubleToStr(gCutTPBV, 2) + " " + gCurrency;
      gSum += vDataSep + "( bad broker )";
      gSum += vDataSep + "Broker closed order with smaller TP.";

      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(vCloseSlips, 0);
      gSum += vDataSep + "100 %";
      gSum += vDataSep + DoubleToStr(vCloseSlipsP, 2) + " " + gCurrency;
      gSum += vDataSep + DoubleToStr(vCloseSlipsV, 2) + " " + gCurrency;
      if      (vCloseSlipsV > 0) { gSum += vDataSep + "( rather good broker )"; } 
      else if (vCloseSlipsV < 0) { gSum += vDataSep + "( rather bad broker )"; }
      else                       { gSum += vDataSep + ""; }
      gSum += vDataSep + "All orders closed by broker with price slip.";
   }

   // separator

   gSum += vDataSep + "&nbsp;";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   
   // Table header

   gSum += vDataSep + "";
   gSum += vDataSep + "Orders";
   gSum += vDataSep + "Ratio";
   gSum += vDataSep + "Profit";
   gSum += vDataSep + "Earn & Loss";
   gSum += vDataSep + "Tips";
   gSum += vDataSep + "Description";
   
   // Quick orders 

   gSum += vDataSep + "Quick orders :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gQuickEarn, 0);
   gSum += vDataSep + DoubleToStr((gQuickEarn / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gQuickEarnP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for scalpers & robots )";
   gSum += vDataSep + "Quick orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gQuickLoss, 0);
   gSum += vDataSep + DoubleToStr((gQuickLoss / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gQuickLossP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for scalpers & robots )";
   gSum += vDataSep + "Quick orders with loss ( profit < 0 ).";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gQuickEarn + gQuickLoss, 0);
   gSum += vDataSep + DoubleToStr(((gQuickEarn + gQuickLoss ) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gQuickEarnP + gQuickLossP, 2) + " " + gCurrency;
   if      (gQuickEarnP + gQuickLossP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good scalping strategy )"; }
   else if (gQuickEarnP + gQuickLossP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad scalping strategy )"; }
   else                                    { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All quick orders.";
   
   // Day trading

   gSum += vDataSep + "Day-trading :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";

   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gDTEarn, 0);
   gSum += vDataSep + DoubleToStr((gDTEarn / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gDTEarnP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for day-traders )";
   gSum += vDataSep + "Day-trading orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gDTLoss, 0);
   gSum += vDataSep + DoubleToStr((gDTLoss / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gDTLossP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for day-traders )";
   gSum += vDataSep + "Day-trading orders with loss ( profit < 0 ).";

   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gDTEarn + gDTLoss, 0);
   gSum += vDataSep + DoubleToStr(((gDTEarn + gDTLoss) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gDTEarnP + gDTLossP, 2) + " " + gCurrency;
   if      (gDTEarnP + gDTLossP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good day-trading strategy )"; }
   else if (gDTEarnP + gDTLossP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad day-trading strategy )"; }
   else                              { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All day-trading orders.";
      
   // Investing

   gSum += vDataSep + "Investing :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";

   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gInvestEarn, 0);
   gSum += vDataSep + DoubleToStr((gInvestEarn / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gInvestEarnP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for investors )";
   gSum += vDataSep + "Long-time orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gInvestLoss, 0);
   gSum += vDataSep + DoubleToStr((gInvestLoss / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gInvestLossP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for investors )";
   gSum += vDataSep + "Long-time orders with loss ( profit < 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gInvestEarn + gInvestLoss, 0);
   gSum += vDataSep + DoubleToStr(((gInvestEarn + gInvestLoss) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gInvestEarnP + gInvestLossP, 2) + " " + gCurrency;
   if      (gInvestEarnP + gInvestLossP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good long-term strategy )"; } 
   else if (gInvestEarnP + gInvestLossP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad long-term strategy )"; }
   else                                      { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All long-term orders.";

   if (gHadOpenFeature) 
   {
      // hedging

      gSum += vDataSep + "Hedging :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";

      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gHedgeEarn, 0);
      gSum += vDataSep + DoubleToStr((gHedgeEarn / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gHedgeEarnP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( good for hedging )";
      gSum += vDataSep + "Hedging orders with earn ( profit > 0 ).";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gHedgeLoss, 0);
      gSum += vDataSep + DoubleToStr((gHedgeLoss / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gHedgeLossP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( not good for hedging )";
      gSum += vDataSep + "Hedging orders with loss ( profit < 0 ).";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gHedgeEarn + gHedgeLoss, 0);
      gSum += vDataSep + DoubleToStr(((gHedgeEarn + gHedgeLoss) / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gHedgeEarnP + gHedgeLossP, 2) + " " + gCurrency;
      if      (gHedgeEarnP + gHedgeLossP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good hedging strategy )"; } 
      else if (gHedgeEarnP + gHedgeLossP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad hedging strategy )"; }
      else                                    { gSum += vDataSep + ""; gSum += vDataSep + ""; }
      gSum += vDataSep + "All hedging orders.";
   }

   // Trader emotions

   gSum += vDataSep + "Trader emotions :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";

   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gCutSLT, 0);
   gSum += vDataSep + DoubleToStr((gCutSLT / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gCutSLTP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good control )";
   gSum += vDataSep + "Orders closed by trader before SL activation ( cut loss ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gCutTPT, 0);
   gSum += vDataSep + DoubleToStr((gCutTPT / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gCutTPTP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( out of control )";
   gSum += vDataSep + "Orders closed by trader before TP activation ( cut profit ).";

   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gCutSLT + gCutTPT, 0);
   gSum += vDataSep + DoubleToStr(((gCutSLT + gCutTPT) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gCutSLTP + gCutTPTP, 2) + " " + gCurrency;
   if      (gCutSLTP + gCutTPTP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good emotion control )"; } 
   else if (gCutSLTP + gCutTPTP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad emotion control )"; }
   else                              { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All orders closed by trader with set SL or TP.";
   
   gSum += vDataSep + "+";
   gSum += vDataSep + DoubleToStr(gNotSet, 0);
   gSum += vDataSep + DoubleToStr((gNotSet / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gNotSetP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "";
   gSum += vDataSep + "All orders closed by trader without SL or TP.";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr((gActivated - gBrokerClosed), 0);
   gSum += vDataSep + DoubleToStr(((gActivated - gBrokerClosed) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr((gActivatedP - gBrokerClosedP), 2) + " " + gCurrency;
   if      (gActivatedP - gBrokerClosedP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good trader strategy )"; } 
   else if (gActivatedP - gBrokerClosedP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad trader strategy )"; }
   else                                       { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All orders closed by trader.";
   
   // Closed by broker

   gSum += vDataSep + "Closed by broker :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";

   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gTPEqual, 0);
   gSum += vDataSep + DoubleToStr((gTPEqual / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTPEqualP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( very liquid market, demo )";
   gSum += vDataSep + "All orders closed by broker with TP requested by trader.";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gSLEqual, 0);
   gSum += vDataSep + DoubleToStr((gSLEqual / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gSLEqualP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( very liquid market, demo )";
   gSum += vDataSep + "All orders closed by broker with SL requested by trader.";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gCloseSlip, 0);
   gSum += vDataSep + DoubleToStr((gCloseSlip / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gCloseSlipP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not very liquid market, real )";
   gSum += vDataSep + "All orders closed by broker with price slip.";

   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gBrokerClosed, 0);
   gSum += vDataSep + DoubleToStr((gBrokerClosed / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gBrokerClosedP, 2) + " " + gCurrency;
   if      (gTPEqualP + gSLEqualP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good SL and TP set )"; } 
   else if (gTPEqualP + gSLEqualP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad SL and TP set )"; } 
   else                                { gSum += vDataSep + ""; gSum += vDataSep + ""; } 
   gSum += vDataSep + "All orders closed by broker ( via SL or TP ).";
   
   // All orders

   gSum += vDataSep + "All orders :";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";
   gSum += vDataSep + "";

   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gSet, 0);
   gSum += vDataSep + DoubleToStr((gSet / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gSetP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( secure strategy )";
   gSum += vDataSep + "All realized orders with SL or TP.";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gNotSet, 0);
   gSum += vDataSep + DoubleToStr((gNotSet / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gNotSetP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( risky strategy )";
   gSum += vDataSep + "All realized orders without SL or TP.";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gActivated, 0);
   gSum += vDataSep + "100 %";
   gSum += vDataSep + DoubleToStr(gActivatedP, 2) + " " + gCurrency;
   if      (gSetP + gNotSetP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good general approach )"; } 
   else if (gSetP + gNotSetP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad general approach )"; }
   else                           { gSum += vDataSep + ""; gSum += vDataSep + ""; }
   gSum += vDataSep + "All realized orders ( except cancelled, currently pending or active ).";
}

// -----------------------------------------------------------------------------------------------------------------------
// Set entry with issue
// -----------------------------------------------------------------------------------------------------------------------

void setEntry()
{
   double vTP = 0, vSL = 0;
   string t1 = "", vHTML = "", vCSV = "";

   if (OrderType() == OP_BUY)
   { 
      t1 = "BUY";
      if (OrderTakeProfit() > 0) { vTP = OrderTakeProfit() - OrderOpenPrice(); }
      if (OrderStopLoss() > 0) { vSL = OrderOpenPrice() - OrderStopLoss(); }
   }
   if (OrderType() == OP_SELL) 
   {
      t1 = "SELL";
      if (OrderTakeProfit() > 0) { vTP = OrderOpenPrice() - OrderTakeProfit(); }
      if (OrderStopLoss() > 0) { vSL = OrderStopLoss() - OrderOpenPrice(); }
   }
   
   if (gPoint != 0) { 
      vTP = MathRound(vTP / gPoint);
      vSL = MathRound(vSL / gPoint);
   }

   if (sHTML)
   {
      vHTML += "<tr>";
         vHTML += "<td>" + (string)OrderSymbol() + "</td>";
         vHTML += "<td>" + (string)OrderTicket() + "</td>";
         vHTML += "<td>" + (string)OrderOpenTime() + "</td>";
         vHTML += "<td>" + (string)OrderCloseTime() + "</td>";
         vHTML += "<td class=\"right\">" + (string)OrderOpenPrice() + "</td>";
         vHTML += "<td class=\"right\">" + (string)OrderClosePrice() + "</td>";
         vHTML += "<td class=\"right\">" + (string)OrderTakeProfit() + "</td>";
         vHTML += "<td class=\"right\">" + (string)OrderStopLoss() + "</td>";
         vHTML += "<td>" + (string)OrderComment() + "</td>";
         vHTML += "<td>" + t1 + "</td>";
         vHTML += "<td class=\"right\">" + (string)vTP + "</td>";
         vHTML += "<td class=\"right\">" + (string)vSL + "</td>";
         vHTML += "<td class=\"right\">" + DoubleToString(OrderProfit(), 2) + "</td>";
         vHTML += "<td>" + gIssue + "</td>";
      vHTML += "</tr>" + "\n";

      if (gShow == 1) { gHTMLe += vHTML; }
      if (gShow == 2) { gHTMLeq += vHTML; }
   }

   if (sCSV)
   {
      vCSV += sSep + (string)OrderSymbol();
      vCSV += sSep + (string)OrderTicket();
      vCSV += sSep + (string)OrderOpenTime();
      vCSV += sSep + (string)OrderCloseTime();
      vCSV += sSep + (string)OrderOpenPrice();
      vCSV += sSep + (string)OrderClosePrice();
      vCSV += sSep + (string)OrderTakeProfit();
      vCSV += sSep + (string)OrderStopLoss();
      vCSV += sSep + (string)OrderComment();
      vCSV += sSep + t1;
      vCSV += sSep + (string)vTP;
      vCSV += sSep + (string)vSL;
      vCSV += sSep + DoubleToString(OrderProfit(), 2);
      vCSV += sSep + gIssue;
      vCSV += sSep + "\n";

      if (gShow == 1) { gCSVe += vCSV; }
      if (gShow == 2) { gCSVeq += vCSV; }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Set summary in HTML format
// -----------------------------------------------------------------------------------------------------------------------

string setSummaryHTML()
{
   string vHTML = "", vArr[];

   StringSplit(gSum, StringGetCharacter("$", 0), vArr);

   vHTML += "<h2>" + vArr[0]+ "</h2>" + "\n";

      vHTML += "<table>"+"\n";
         
         for (int i=1; i<ArraySize(vArr); i+=7)
         {
            vHTML += "<tr>";
               vHTML += "<td class=\"right\"><b>" + vArr[i] + "</b></td>";
               vHTML += "<td class=\"right\"><b>" + vArr[i+1] + "</b></td>";
               vHTML += "<td class=\"right\"><b>" + vArr[i+2] + "</b></td>";
               vHTML += "<td class=\"right\"><b>" + vArr[i+3] + "</b></td>";
               vHTML += "<td class=\"right\"><b>" + vArr[i+4] + "</b></td>";
               vHTML += "<td>" + vArr[i+5] + "</td>";
               vHTML += "<td>" + vArr[i+6] + "</td>";
            vHTML += "</tr>" + "\n";
         }

      vHTML += "</table>" + "\n";

   return vHTML;
}

// -----------------------------------------------------------------------------------------------------------------------
// Create HTML page
// -----------------------------------------------------------------------------------------------------------------------

void setHTMLPage()
{
   string vHTML = "", vHead = "";

   vHead += "<thead>" + "\n";
      vHead += "<tr>";
         vHead += "<th><b>Symbol</b></td>";
         vHead += "<th><b>Ticket</b></td>";
         vHead += "<th><b>Open time</b></td>";
         vHead += "<th><b>Closed time</b></td>";
         vHead += "<th class=\"right\"><b>Open price</b></td>";
         vHead += "<th class=\"right\"><b>Closed price</b></td>";
         vHead += "<th class=\"right\"><b>TP price</b></td>";
         vHead += "<th class=\"right\"><b>SL price</b></td>";
         vHead += "<th><b>Comment</b></td>";
         vHead += "<th><b>Type</b></td>";
         vHead += "<th class=\"right\"><b>TP points</b></td>";
         vHead += "<th class=\"right\"><b>SL points</b></td>";
         vHead += "<th class=\"right\"><b>Profit</b></td>";
         vHead += "<th><b>Issue</b></td>";
      vHead += "</tr>" + "\n";
   vHead += "</thead>" + "\n";

   vHTML += "<!DOCTYPE html>" + "\n";
   vHTML += "<html>" + "\n";
      vHTML += "<head>" + "\n";
         vHTML += "<title>" + (string)AccountNumber() + ", " + (string)AccountCompany() + "</title>" + "\n";
      vHTML += "<body>" + "\n";
   
         vHTML += "<style>" + "\n";
            vHTML += ".box-page { width: 100%; }" + "\n";
            vHTML += "table { width: auto; margin: 60px 0px; }" + "\n";
            vHTML += "td { padding: 5px 15px 5px 15px; border-top: 1px dotted red; }" + "\n";
            vHTML += ".right { text-align: right; }" + "\n";
         vHTML += "</style>" + "\n";
   
         vHTML += "<div class=\"box-page\">";

            vHTML += "<h1>Account: " + (string)AccountNumber() + ", " + (string)AccountCompany() + "</h1>" + "\n";
            vHTML += "</br></br>" + "\n";
   
            vHTML += setSummaryHTML();

            vHTML += "<h2>Orders with issues closed by broker:</h2>";

            vHTML += "<table>" + "\n";
               vHTML += vHead;
               vHTML += "<tbody>" + "\n";
                  vHTML += gHTMLe;
               vHTML += "</tbody>" + "\n";
            vHTML += "</table>" + "\n";
            
            if (!gHadOpenFeature)
            {
               vHTML += "<h2>Orders closed by broker with expected price for TP or SL:</h2>";
   
               vHTML += "<h3>" + gOpenInfo + "</h3>";
   
               vHTML += "<table>" + "\n";
                  vHTML += vHead;
                  vHTML += "<tbody>" + "\n";
                     vHTML += gHTMLeq;
                  vHTML += "</tbody>" + "\n";
               vHTML += "</table>" + "\n";
            }

            vHTML += "Report generated by: ";
            vHTML += "<a href=\"https://github.com/dprojects/MetaTrader-tools/";
            vHTML += "blob/master/MQL4/Scripts/DL_check_broker.mq4\">DL_check_broker.mq4</a>" + "\n";
            vHTML += "</br></br>" + "\n";

         vHTML += "</div>" + "\n";
      vHTML += "</body>" + "\n";
   vHTML += "</html>" + "\n";

   gHTML = vHTML;
}

// -----------------------------------------------------------------------------------------------------------------------
// Save HTML output to file
// -----------------------------------------------------------------------------------------------------------------------

void setHTMLFile() 
{
   int    vFile = 0;
   string vFileName = "orders_issues_" + (string)AccountNumber() + ".html";
   string vFileDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\";
   
   setHTMLPage();

   vFile = FileOpen(vFileName, FILE_WRITE | FILE_TXT);
   
   if (vFile != INVALID_HANDLE)
   {
      FileWrite(vFile, gHTML);
      FileClose(vFile);
      
      Print(sCol + "The HTML report has been created at:" + vFileDir + vFileName);
   }
   else 
   {
      Print("File open failed, error ",GetLastError());
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Set summary in CSV format
// -----------------------------------------------------------------------------------------------------------------------

string setSummaryCSV()
{
   string vCSV = "", vArr[];

   StringSplit(gSum, StringGetCharacter("$", 0), vArr);

   vCSV += vArr[0] + "\n\n";
   
   for (int i=1; i<ArraySize(vArr); i+=7)
   {
      vCSV += sSep + vArr[i];
      vCSV += sSep + vArr[i+1];
      vCSV += sSep + vArr[i+2];
      vCSV += sSep + vArr[i+3];
      vCSV += sSep + vArr[i+4];
      vCSV += sSep + vArr[i+5];
      vCSV += sSep + vArr[i+6];
      vCSV += sSep + "\n";
   }

   return vCSV;
}

// -----------------------------------------------------------------------------------------------------------------------
// Create CSV page
// -----------------------------------------------------------------------------------------------------------------------

void setCSVPage()
{
   string vCSV = "", vHead = "";

   vHead += "\n";
   vHead += sSep + "Symbol";
   vHead += sSep + "Ticket";
   vHead += sSep + "Open time";
   vHead += sSep + "Closed time";
   vHead += sSep + "Open price";
   vHead += sSep + "Closed price";
   vHead += sSep + "TP price";
   vHead += sSep + "SL price";
   vHead += sSep + "Comment";
   vHead += sSep + "Type";
   vHead += sSep + "TP points";
   vHead += sSep + "SL points";
   vHead += sSep + "Profit";
   vHead += sSep + "Issue";
   vHead += sSep + "\n";
         
   vCSV += "Account: " + (string)AccountNumber() + ", " + (string)AccountCompany() + "\n\n";
   
   vCSV += setSummaryCSV() + "\n\n";

   vCSV += "Orders with issues closed by broker:" + "\n";
   vCSV += vHead;
   vCSV += gCSVe;
            
   if (!gHadOpenFeature)
   {
      vCSV += "\n\n";

      vCSV += "Orders closed by broker with expected price for TP or SL:" + "\n\n";
      vCSV += gOpenInfo + "\n\n";
      vCSV += vHead;
      vCSV += gCSVeq;
   }

   vCSV += "\n\n";

   vCSV += "Report generated by: ";
   vCSV += "\"https://github.com/dprojects/MetaTrader-tools/";
   vCSV += "blob/master/MQL4/Scripts/DL_check_broker.mq4\""+"\n";
   
   gCSV = vCSV;
}

// -----------------------------------------------------------------------------------------------------------------------
// Save CSV output to file
// -----------------------------------------------------------------------------------------------------------------------

void setCSVFile() 
{
   int    vFile = 0;
   string vFileName = "orders_issues_" + (string)AccountNumber() + ".csv";
   string vFileDir = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files\\";
   
   setCSVPage();

   vFile = FileOpen(vFileName, FILE_WRITE | FILE_TXT);
   
   if (vFile != INVALID_HANDLE)
   {
      FileWrite(vFile, gCSV);
      FileClose(vFile);
      
      Print(sCol + "The CSV report has been created at:" + vFileDir + vFileName);
   }
   else 
   {
      Print("File open failed, error ",GetLastError());
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get bigger TP or SL (closed too late)
// -----------------------------------------------------------------------------------------------------------------------

void getBigger() 
{
   double vCSlip = 0, vOSlipV = 0;
   
   if (OrderType() == OP_BUY)
   {    
      // LOSS: bigger SL (SL slip)
      if (OrderStopLoss() > 0 && OrderClosePrice() < OrderStopLoss())
      { 
         vCSlip = OrderStopLoss() - OrderClosePrice();
         if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }
         
         if (gIsOpenFeature)
         {
            if (gOSlip > 0) {
               
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * (vCSlip + gOSlipAbs)); gOSCBLV += vOSlipV;
               
               gIssue += "OPEN+" + (string)gOSlipAbs + " & SL+" + (string)vCSlip + " "; 
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               gShow = 1; 
            }
            if (gOSlip < 0) {
               
               gIssue += "OPEN-" + (string)gOSlipAbs + " & SL+" + (string)vCSlip + " "; 
               gShow = 1;

               if (gOSlipAbs == vCSlip) 
               {
                  gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                  gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;                  
               }
               if (gOSlipAbs < vCSlip)
               {
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                  gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs > vCSlip)
               {
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBEV += vOSlipV;
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
            }
         }
         else 
         {
            gBigSLB++; gBigSLBP += OrderProfit() + OrderSwap();
            gBigSLBV += gPointVal * vCSlip;

            gIssue += "slip SL+" + (string)vCSlip + " ";
            gIssue += "=> loss: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
            gShow = 1;
         }
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() > OrderTakeProfit())
      { 
         vCSlip = OrderClosePrice() - OrderTakeProfit(); 
         if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

         if (gIsOpenFeature)
         {
            if (gOSlip > 0) 
            { 
               gIssue += "OPEN+" + (string)gOSlipAbs + " & TP+" + (string)vCSlip + " ";
               gShow = 1;

               if (gOSlipAbs == vCSlip) 
               {
                  gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                  gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs > vCSlip)
               {
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBLV += vOSlipV;
                  gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs < vCSlip)
               {
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBEV += vOSlipV;
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
            }
            if (gOSlip < 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBEV += vOSlipV;

               gIssue += "OPEN-" + (string)gOSlipAbs + " & TP+" + (string)vCSlip + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               gShow = 1;
            }
         }
         else 
         {
            gBigTPB++; gBigTPBP += OrderProfit() + OrderSwap(); 
            gBigTPBV += gPointVal * vCSlip;

            gIssue += "slip TP+" + (string)vCSlip + " ";
            gIssue += "=> earn: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
            gShow = 1;
         }
      }
   }
   
   if (OrderType() == OP_SELL)
   {  
      // LOSS: bigger SL (SL slip)      
      if (OrderStopLoss() > 0 && OrderClosePrice() > OrderStopLoss())
      { 
         vCSlip = OrderClosePrice() - OrderStopLoss();
         if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

         if (gIsOpenFeature)
         {
            if (gOSlip > 0) 
            { 
               gIssue += "OPEN+" + (string)gOSlipAbs + " & SL+" + (string)vCSlip + " ";
               gShow = 1;

               if (gOSlipAbs == vCSlip) 
               {
                  gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                  gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs < vCSlip)
               {
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                  gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs > vCSlip)
               {
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBEV += vOSlipV;
                  gIssue += "earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }               
            }
            if (gOSlip < 0) 
            { 
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBLV += vOSlipV;

               gIssue += "OPEN-" + (string)gOSlipAbs + " & SL+" + (string)vCSlip + " ";
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency; 
               gShow = 1; 
            }
         }
         else 
         {
            gBigSLB++; gBigSLBP += OrderProfit() + OrderSwap(); 
            gBigSLBV += gPointVal * vCSlip;

            gIssue += "slip SL+" + (string)vCSlip + " ";
            gIssue += "=> loss: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
            gShow = 1;
         }
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() < OrderTakeProfit())
      { 
         vCSlip = OrderTakeProfit() - OrderClosePrice();
         if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

         if (gIsOpenFeature)
         {
            if (gOSlip > 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBEV += vOSlipV;

               gIssue += "OPEN+" + (string)gOSlipAbs + " & TP+" + (string)vCSlip + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency; 
               gShow = 1; 
            }
            if (gOSlip < 0) 
            { 
               gIssue += "OPEN-" + (string)gOSlipAbs + " & TP+" + (string)vCSlip + " ";
               gShow = 1;

               if (gOSlipAbs == vCSlip) 
               {
                  gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                  gIssue += "returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs > vCSlip)
               {
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBLV += vOSlipV;
                  gIssue += "loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlipAbs < vCSlip)
               {
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                  gIssue += "earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
            }
         }
         else 
         {
            gBigTPB++; gBigTPBP += OrderProfit() + OrderSwap();
            gBigTPBV += gPointVal + vCSlip;

            gIssue += "slip TP+" + (string)vCSlip + " ";
            gIssue += "=> earn: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
            gShow = 1;
         }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get smaller TP or SL (closed too fast)
// -----------------------------------------------------------------------------------------------------------------------

void getSmaller() 
{
   double vCSlip = 0, vOSlipV = 0;
   string k = OrderComment();
   
   if (OrderType() == OP_BUY)
   {    
      // EARN: smaller SL (faster closed SL)
      if (   OrderStopLoss() > 0 && 
             OrderClosePrice() < OrderOpenPrice() && 
             OrderClosePrice() > OrderStopLoss()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[sl]", 0) != -1) 
         { 
            vCSlip = OrderClosePrice() - OrderStopLoss(); 
            if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

            if (gIsOpenFeature)
            {
               if (gOSlip > 0) 
               { 
                  gIssue += "OPEN+" + (string)gOSlipAbs + " & SL-" + (string)vCSlip + " "; 
                  gShow = 1;

                  if (gOSlipAbs == vCSlip) 
                  {
                     gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                     gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs > vCSlip)
                  {
                     gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBLV += vOSlipV;
                     gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs < vCSlip)
                  {
                     
                     gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBEV += vOSlipV;
                     gIssue += "=> good, earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
               }
               if (gOSlip < 0) 
               { 
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBEV += vOSlipV;

                  gIssue += "OPEN-" + (string)gOSlipAbs + " & SL-" + (string)vCSlip + " "; 
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency; 
                  gShow = 1; 
               }
            }
            else 
            {
               gCutSLB++; gCutSLBP += OrderProfit() + OrderSwap(); 
               gCutSLBV += gPointVal * vCSlip;

               gIssue += "slip SL-" + (string)vCSlip + " ";
               gIssue += "=> earn: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
               gShow = 1;
            }
         }
         
         // closed by trader
         if (StringFind(k, "[sl]", 0) == -1) { gCutSLT++; gCutSLTP += OrderProfit() + OrderSwap(); }
      }
      
      // LOSS: smaller TP (faster closed TP)
      if (   OrderTakeProfit() > 0 && 
             OrderClosePrice() > OrderOpenPrice() && 
             OrderClosePrice() < OrderTakeProfit()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[tp]", 0) != -1) 
         { 
            vCSlip = OrderTakeProfit() - OrderClosePrice();
            if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

            if (gIsOpenFeature)
            {
               if (gOSlip > 0) 
               { 
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBLV += vOSlipV;

                  gIssue += "OPEN+" + (string)gOSlipAbs + " & TP-" + (string)vCSlip + " "; 
                  gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency; 
                  gShow = 1; 
               }
               if (gOSlip < 0) 
               { 
                  gIssue += "OPEN-" + (string)gOSlipAbs + " & TP-" + (string)vCSlip + " "; 
                  gShow = 1;

                  if (gOSlipAbs == vCSlip) 
                  {
                     gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                     gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs < vCSlip)
                  {
                     gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                     gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs > vCSlip)
                  {
                     gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBEV += vOSlipV;
                     gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
               }
            }
            else 
            {
               gCutTPB++; gCutTPBP += OrderProfit() + OrderSwap(); 
               gCutTPBV += gPointVal * vCSlip;

               gIssue += "slip TP-" + (string)vCSlip + " ";
               gIssue += "=> loss: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
               gShow = 1;
            }
         }

         // closed by trader
         if (StringFind(k, "[tp]", 0) == -1) { gCutTPT++; gCutTPTP += OrderProfit() + OrderSwap(); }
      }
   }
    
   if (OrderType() == OP_SELL)
   {  
      // EARN: smaller SL (faster closed SL)
      if (   OrderStopLoss() > 0 && 
             OrderClosePrice() > OrderOpenPrice() && 
             OrderClosePrice() < OrderStopLoss()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[sl]", 0) != -1) 
         { 
            vCSlip = OrderStopLoss() - OrderClosePrice();
            if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }
            
            if (gIsOpenFeature)
            {
               if (gOSlip > 0) 
               { 
                  gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBEV += vOSlipV;

                  gIssue += "OPEN+" + (string)gOSlipAbs + " & SL-" + (string)vCSlip + " "; 
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  gShow = 1; 
               }
               if (gOSlip < 0) 
               { 
                 gIssue += "OPEN-" + (string)gOSlipAbs + " & SL-" + (string)vCSlip + " "; 
                 gShow = 1; 

                 if (gOSlipAbs == vCSlip) 
                  {
                     gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                     gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs > vCSlip)
                  {
                     gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBLV += vOSlipV;
                     gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs < vCSlip)
                  {
                     gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBEV += vOSlipV;
                     gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
               }
            }
            else 
            {
               gCutSLB++; gCutSLBP += OrderProfit() + OrderSwap(); 
               gCutSLBV += gPointVal * vCSlip;
               
               gIssue += "slip SL-" + (string)vCSlip + " ";
               gIssue += "=> earn: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
               gShow = 1;
            }
         }

         // closed by trader
         if (StringFind(k, "[sl]", 0) == -1) { gCutSLT++; gCutSLTP += OrderProfit() + OrderSwap(); }
      }
      
      // LOSS: smaller TP (faster closed TP)
      if (   OrderTakeProfit() > 0 && 
             OrderClosePrice() < OrderOpenPrice() && 
             OrderClosePrice() > OrderTakeProfit()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[tp]", 0) != -1) 
         { 
            vCSlip = OrderClosePrice() - OrderTakeProfit();
            if (gPoint != 0) { vCSlip = MathRound(vCSlip / gPoint); }

            if (gIsOpenFeature)
            {
               if (gOSlip > 0) 
               { 
                 gIssue += "OPEN+" + (string)gOSlipAbs + " & TP-" + (string)vCSlip + " "; 
                 gShow = 1;

                 if (gOSlipAbs == vCSlip) 
                  {
                     gOSCBH++; gOSCBHP += OrderProfit() + OrderSwap();
                     gIssue += "=> returned: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs < vCSlip)
                  {
                     gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                     gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
                  if (gOSlipAbs > vCSlip)
                  {
                     gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
                     vOSlipV = (gPointVal * (gOSlipAbs - vCSlip)); gOSCBEV += vOSlipV;
                     gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  }
               }
               if (gOSlip < 0) 
               { 
                  gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
                  vOSlipV = (gPointVal * (gOSlipAbs + vCSlip)); gOSCBLV += vOSlipV;

                  gIssue += "OPEN-" + (string)gOSlipAbs + " & TP-" + (string)vCSlip + " "; 
                  gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
                  gShow = 1; 
               }
            }
            else 
            {
               gCutTPB++; gCutTPBP += OrderProfit() + OrderSwap(); 
               gCutTPBV += gPointVal * vCSlip;

               gIssue += "slip TP-" + (string)vCSlip + " ";
               gIssue += "=> loss: " + DoubleToStr(gPointVal * vCSlip, 2) + " " + gCurrency; 
               gShow = 1;
            }
         }

         // closed by trader
         if (StringFind(k, "[tp]", 0) == -1) { gCutTPT++; gCutTPTP += OrderProfit() + OrderSwap(); }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed with expected TP or SL price
// -----------------------------------------------------------------------------------------------------------------------

void getEqual() 
{
   if (OrderTakeProfit() == OrderClosePrice()) 
   { 
      gTPEqual++; gTPEqualP += OrderProfit() + OrderSwap();
      gShow = 2; gIssue += "TP size? "; 
   }
   if (OrderStopLoss() == OrderClosePrice()) 
   { 
      gSLEqual++; gSLEqualP += OrderProfit() + OrderSwap();
      gShow = 2; gIssue += "SL size? "; }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed with set TP or SL price
// -----------------------------------------------------------------------------------------------------------------------

void getWithSet() 
{
   if (OrderTakeProfit() == 0 && OrderStopLoss() >  0) { gSet++; gSetP += OrderProfit() + OrderSwap(); }
   if (OrderTakeProfit() >  0 && OrderStopLoss() == 0) { gSet++; gSetP += OrderProfit() + OrderSwap(); }
   if (OrderTakeProfit() >  0 && OrderStopLoss() >  0) { gSet++; gSetP += OrderProfit() + OrderSwap(); }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed without set TP and SL price
// -----------------------------------------------------------------------------------------------------------------------

void getWithNotSet() 
{
   if (OrderTakeProfit() == 0 && OrderStopLoss() == 0) { gNotSet++; gNotSetP += OrderProfit() + OrderSwap(); }
}

// -----------------------------------------------------------------------------------------------------------------------
// Order time
// -----------------------------------------------------------------------------------------------------------------------

void getOrderTime() 
{
   datetime vTime;
   MqlDateTime vT;
   
   vTime = OrderCloseTime() - OrderOpenTime();
   TimeToStruct(vTime, vT);
   
   if (vT.year == 1970 && vT.mon == 1 && vT.day == 1 && vT.hour == 0 && vT.min == 0 && vT.sec < 3) {
   
      if (OrderProfit() > 0) 
      { 
         gQuickEarn++; gQuickEarnP += OrderProfit() + OrderSwap();
         gIssue = "Quick, " + gIssue; gShow = 1; 
      }
      if (OrderProfit() < 0) 
      { 
         gQuickLoss++; gQuickLossP += OrderProfit() + OrderSwap();
         gIssue = "Quick, " + gIssue; gShow = 1;
      }
   }
   else if (vT.year == 1970 && vT.mon == 1 && vT.day == 1) {
   
      if (OrderProfit() > 0) 
      { 
         gDTEarn++; gDTEarnP += OrderProfit() + OrderSwap();
         gIssue = "Day-trade, " + gIssue;
      }
      if (OrderProfit() < 0) 
      { 
         gDTLoss++; gDTLossP += OrderProfit() + OrderSwap();
         gIssue = "Day-trade, " + gIssue;
      }
   }
   else 
   {
      if (OrderProfit() > 0) 
      { 
         gInvestEarn++; gInvestEarnP += OrderProfit() + OrderSwap();
         gIssue = "Investing, " + gIssue;
      }
      if (OrderProfit() < 0) 
      { 
         gInvestLoss++; gInvestLossP += OrderProfit() + OrderSwap();
         gIssue = "Investing, " + gIssue;
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders with hedging
// -----------------------------------------------------------------------------------------------------------------------

void getHedge() 
{
   string k = "", kExt[];
   string vOrderType = "";
   
   // exit if open feature not available in comment
   if (!gIsOpenFeature) { return; }

   // set comment
   k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt);
   
   // set hedge
   vOrderType = (string)kExt[5]; 
   if ( StringFind(vOrderType, "H", 0) != -1 ) 
   {
      if (OrderProfit() > 0) { gHedgeEarn++; gHedgeEarnP += OrderProfit() + OrderSwap(); }
      if (OrderProfit() < 0) { gHedgeLoss++; gHedgeLossP += OrderProfit() + OrderSwap(); }
   } 
}

// -----------------------------------------------------------------------------------------------------------------------
// Orders with open price slip. In fact you can't predict if the different open price 
// will be good or bad in the future.
// -----------------------------------------------------------------------------------------------------------------------

void getOpenSlip() 
{
   int    vShow = 0;
   double vOSlipV = 0;
   string k = OrderComment();

   // exit if open feature not available in comment
   if (!gIsOpenFeature) { return; }

   if (OrderOpenPrice() != gOpenReq)
   {
      // there is open slip
      gOSA++; gOSAP += OrderProfit() + OrderSwap(); gShow = 1;
      
      // open slip but no points back (TP equal)
      if (OrderClosePrice() == OrderTakeProfit())
      {
         if (OrderType() == OP_BUY)
         {  
            // smaller TP
            if (gOSlip > 0) 
            { 
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap();
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBLV += vOSlipV;

               gIssue += "OPEN+ => TP-" + (string)gOSlipAbs + " "; 
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
            // bigger TP
            if (gOSlip < 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBEV += vOSlipV;

               gIssue += "OPEN- => TP+" + (string)gOSlipAbs + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++; 
            }
         }
         if (OrderType() == OP_SELL)
         {
            // smaller TP
            if (gOSlip < 0) 
            { 
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBLV += vOSlipV;

               gIssue += "OPEN- => TP-" + (string)gOSlipAbs + " "; 
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
            // bigger TP
            if (gOSlip > 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBEV += vOSlipV;

               gIssue += "OPEN+ => TP+" + (string)gOSlipAbs + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
         }
      }
      
      // open slip but no points back (SL equal)
      if (OrderClosePrice() == OrderStopLoss())
      {
         if (OrderType() == OP_BUY)
         {
            // bigger SL
            if (gOSlip > 0) 
            { 
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBLV += vOSlipV;

               gIssue += "OPEN+ => SL+" + (string)gOSlipAbs + " "; 
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
            // smaller SL
            if (gOSlip < 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBEV += vOSlipV;

               gIssue += "OPEN- => SL-" + (string)gOSlipAbs + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
         }
         if (OrderType() == OP_SELL)
         {
            // bigger SL
            if (gOSlip < 0) 
            { 
               gOSCBL++; gOSCBLP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBLV += vOSlipV;

               gIssue += "OPEN- => SL+" + (string)gOSlipAbs + " "; 
               gIssue += "=> loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
            // smaller SL
            if (gOSlip > 0) 
            { 
               gOSCBE++; gOSCBEP += OrderProfit() + OrderSwap(); 
               vOSlipV = (gPointVal * gOSlipAbs); gOSCBEV += vOSlipV;

               gIssue += "OPEN+ => SL-" + (string)gOSlipAbs + " "; 
               gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               vShow++;
            }
         }
      }
      
      // if no case but there is open slip
      if (vShow == 0) 
      { 
         // you have to know requested close price to find out if the close price slip was there
         // so you can't calculate simply if this was earn or loss
         if (StringFind(k, "[tp]", 0) == -1 && StringFind(k, "[sl]", 0) == -1) 
         { 
            gIssue += "Closed by trader, ";
            
            // need to know requested close price to be sure there was no points back
            vOSlipV = (gPointVal * gOSlipAbs);

            if (OrderType() == OP_BUY)
            {  
               if (gOSlip > 0) 
               { 
                  gOSCTL++; gOSCTLP += OrderProfit() + OrderSwap();
                  gOSCTLV += vOSlipV;
   
                  gIssue += "OPEN+" + (string)gOSlipAbs + " "; 
                  gIssue += "=> possible loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlip < 0) 
               { 
                  gOSCTE++; gOSCTEP += OrderProfit() + OrderSwap();
                  gOSCTEV += vOSlipV;

                  gIssue += "OPEN-" + (string)gOSlipAbs + " "; 
                  gIssue += "=> possible earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
            }
            if (OrderType() == OP_SELL)
            {
               if (gOSlip < 0) 
               { 
                  gOSCTL++; gOSCTLP += OrderProfit() + OrderSwap();
                  gOSCTLV += vOSlipV;

                  gIssue += "OPEN-" + (string)gOSlipAbs + " "; 
                  gIssue += "=> possible loss: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
               if (gOSlip > 0) 
               { 
                  gOSCTE++; gOSCTEP += OrderProfit() + OrderSwap();
                  gOSCTEV += vOSlipV;

                  gIssue += "OPEN+" + (string)gOSlipAbs + " "; 
                  gIssue += "=> possible earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
               }
            }
         }
         else
         {
            gIssue += "OPEN slip, unrecognized type";
         }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed by Broker
// -----------------------------------------------------------------------------------------------------------------------

void getByBroker() 
{
   string k = OrderComment(); 
   if (StringFind(k, "[tp]", 0) != -1 || StringFind(k, "[sl]", 0) != -1) 
   { 
      gBrokerClosed++; 
      gBrokerClosedP += OrderProfit() + OrderSwap(); 
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get close slip orders 
// -----------------------------------------------------------------------------------------------------------------------

void getCloseSlip() 
{
   string k = OrderComment(); 
   if (
         ( StringFind(k, "[tp]", 0) != -1 && OrderClosePrice() != OrderTakeProfit() ) ||
         ( StringFind(k, "[sl]", 0) != -1 && OrderClosePrice() != OrderStopLoss()   )
      ) 
   { 
      gCloseSlip++; gCloseSlipP += OrderProfit() + OrderSwap(); 
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// MAIN
// -----------------------------------------------------------------------------------------------------------------------

void OnStart()
{
   int vTotal = OrdersHistoryTotal();
   
   Print("");
   Print("");
   Print(sLine);

   if (vTotal == 0) { Print("ERROR: No orders found."); return; }

   for (int i=0; i<vTotal; i++) 
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
     
      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
         setGlobals();                                     // set global values for selected order
   
         getBigger();                                      // bigger TP or SL
         getSmaller();                                     // smaller TP or SL

         getWithSet();                                     // with set TP or SL
         getWithNotSet();                                  // with not set TP or SL
         getOrderTime();                                   // quick, day-trade, long-time orders
         getEqual();                                       // expected TP or SL price
         getOpenSlip();                                    // open slip with expected TP or SL price
         getByBroker();                                    // all orders closed by Broker
         getHedge();                                       // hedging orders
         getCloseSlip();                                   // close slip (via TP or SL)

         gActivated++;                                     // all olders but only activated
         gActivatedP += OrderProfit() + OrderSwap();       // money flow

         if (gShow == 1 || gShow == 2) { setEntry(); }     // issues
      }
   }
   
   setSummary();                                           // calculate final result
   
   if (sHTML) { setHTMLFile(); }                           // save HTML output to file 
   if (sCSV) { setCSVFile(); }                             // save CSV output to file

   Print(sLine);
}
