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
// CODING STANDARDS HERE
// -----------------------------------------------------------------------------------------------------------------------

// prefix g - means Global variable
// prefix s - means Settings variable
// prefix v - means Variable (local)

// -----------------------------------------------------------------------------------------------------------------------
// SETTINGS
// -----------------------------------------------------------------------------------------------------------------------

bool   sHTML = true;    // generate HTML output
bool   sCSV  = true;    // generate CSV output

string sSep  = ";";     // CSV entry separator, for converters

// for console log
string sCol  = " | ";   // left padding
string sLine = sCol +
                        "--------------------------------------------------------------------------------" +
                        "--------------------------------------------------------------------------------" +
                        "--------------------------------------------------------------------------------";

// -----------------------------------------------------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------------------------------------------------

// Open Slip Closed by Broker

double gOSCBH = 0;       // Honest return points
double gOSCBHP = 0;      // Profit

double gOSCBE = 0;       // Earn return points
double gOSCBEP = 0;      // Profit
double gOSCBEV = 0;      // points Value

double gOSCBL = 0;       // Loss return points
double gOSCBLP = 0;      // Profit
double gOSCBLV = 0;      // points Value

// Open Slip Closed by Trader

double gOSCTE = 0;       // Earn return points
double gOSCTEP = 0;      // Profit
double gOSCTEV = 0;      // points Value

double gOSCTL = 0;       // Loss return points
double gOSCTLP = 0;      // Profit
double gOSCTLV = 0;      // points Value

// Open Slip

double gOSA = 0;         // All
double gOSAP = 0;        // Profit
double gOSAV = 0;        // points Value

// close slip

double gBigTPB = 0;      // Bigger Take Profit closed by Broker (good)
double gBigTPBP = 0;     // Profit
double gBigTPBV = 0;     // points Value

double gCutSLB = 0;      // Cut Stop Loss closed by Broker (good)
double gCutSLBP = 0;     // Profit
double gCutSLBV = 0;     // points Value

double gCutTPB = 0;      // Cut Take Profit closed by Broker (bad)
double gCutTPBP = 0;     // Profit
double gCutTPBV = 0;     // points Value

double gBigSLB = 0;      // Bigger Stop Loss closed by Broker (bad)
double gBigSLBP = 0;     // Profit
double gBigSLBV = 0;     // points Value

// all orders

double gCloseSlip = 0;   // Close price Slip
double gCloseSlipP = 0;  // Profit

double gClosedB = 0;     // Closed by Broker
double gClosedBP = 0;    // Profit

// closed by trader

double gCutTPT = 0;      // Cut Take Profit closed by Trader (trader closed earlier and make possible loss)
double gCutTPTP = 0;     // Profit

double gCutSLT = 0;      // Cut Stop Loss closed by Trader (trader closed earlier and make possible profit)
double gCutSLTP = 0;     // Profit

// related to order time

double gTimeQrE = 0;     // Time Quick with result Earn
double gTimeQrEP = 0;    // Profit

double gTimeQrL = 0;     // Time Quick with result Loss
double gTimeQrLP = 0;    // Profit

double gTimeDTrE = 0;    // Time Day-Trade with result Earn
double gTimeDTrEP = 0;   // Profit

double gTimeDTrL = 0;    // Time Day-Trade with result Loss
double gTimeDTrLP = 0;   // Profit

double gTimeIrE = 0;     // Time Invest with result Earn
double gTimeIrEP = 0;    // Profit

double gTimeIrL = 0;     // Time Invest with result Loss
double gTimeIrLP = 0;    // Profit

// related to order type

double gTypeHrE = 0;     // Type Hedge and with result Earn 
double gTypeHrEP = 0;    // Profit

double gTypeHrL = 0;     // Type Hedge and with result Loss 
double gTypeHrLP = 0;    // Profit

double gTypePSrE = 0;    // Type Pending Stop and with result Earn 
double gTypePSrEP = 0;   // Profit

double gTypePSrL = 0;    // Type Pending stop and with result Loss 
double gTypePSrLP = 0;   // Profit

double gTypePLrE = 0;    // Type Pending Limit and with result Earn 
double gTypePLrEP = 0;   // Profit

double gTypePLrL = 0;    // Type Pending Limit and with result Loss 
double gTypePLrLP = 0;   // Profit

double gTypeIrE = 0;     // Type Instant execution and with result Earn 
double gTypeIrEP = 0;    // Profit

double gTypeIrL = 0;     // Type Instant execution and with result Loss
double gTypeIrLP = 0;    // Profit

// other stats

double gSLEqual = 0;     // Stop Loss and Equal closed price (no slip at the end of order)
double gSLEqualP = 0;    // Profit

double gTPEqual = 0;     // Take Profit and Equal closed price (no slip at the end of order)
double gTPEqualP = 0;    // Profit

double gSTPSL = 0;       // orders with Set TP or SL
double gSTPSLP = 0;      // Profit

double gNTPSL = 0;       // orders with Not set TP or SL
double gNTPSLP = 0;      // Profit

// all orders

double gActivated = 0;   // Activated
double gActivatedP = 0;  // Profit

// switches

int    gShow = 0;
bool   gHadOpenFeature = false;
bool   gIsOpenFeature = false;

// calculation

double gPoint = 0;
double gOpenReq = 0;
double gPointVal = 0;
double gOSlip = 0;
double gOSlipAbs = 0;
string gCurrency = AccountCurrency();

// content

string gHTML = "";
string gHTMLe = "";
string gHTMLeq = "";

string gCSV = "";
string gCSVe = "";
string gCSVeq = "";

// summary

string gIssue = "";
string gSum = "";
string gOpenInfo  = "";

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
   else // if there is no open feature try to guess point value using profit
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
      vRatioA = gOSCBH + gOSCBE + gTPEqual + gSLEqual + gOSCBL;
      if (vRatioA != 0) { vRatioG = ( (gOSCBH + gOSCBE + gTPEqual + gSLEqual) / vRatioA ) * 100; }

      gOSA  = gOSCBE  + gOSCBL  + gOSCTE  + gOSCTL;
      gOSAP = gOSCBEP + gOSCBLP + gOSCTEP + gOSCTLP;
      gOSAV = gOSCBEV - gOSCBLV + gOSCTEV - gOSCTLV;
   }
   else
   {
      vRatioA = gBigTPB + gCutSLB + gTPEqual + gSLEqual + gBigSLB + gCutTPB;
      if (vRatioA != 0) { vRatioG = ( (gBigTPB + gCutSLB + gTPEqual + gSLEqual) / vRatioA ) * 100; }

      vCloseSlips  = gBigTPB  + gCutSLB  + gBigSLB  + gCutTPB;
      vCloseSlipsP = gBigTPBP + gCutSLBP + gBigSLBP + gCutTPBP;
      vCloseSlipsV = gBigTPBV + gCutSLBV - gBigSLBV - gCutTPBV;
   }

   vR += DoubleToStr(vRatioG, 0) + "%, ";

   if (vRatioG == 100)    { vR += "DEMO ?"; } 
   else if (vRatioG > 80) { vR += "VERY GOOD"; } 
   else if (vRatioG > 50) { vR += "GOOD"; }
   else if (vRatioG > 20) { vR += "BAD"; }
   else if (vRatioG >  0) { vR += "VERY BAD"; }
   else                   { vR += "BROKER NOT INVOLVED"; }

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
      gSum += vDataSep + "";
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
   gSum += vDataSep + DoubleToStr(gTimeQrE, 0);
   gSum += vDataSep + DoubleToStr((gTimeQrE / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeQrEP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for scalpers & robots )";
   gSum += vDataSep + "Quick orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gTimeQrL, 0);
   gSum += vDataSep + DoubleToStr((gTimeQrL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeQrLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for scalpers & robots )";
   gSum += vDataSep + "Quick orders with loss ( profit < 0 ).";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gTimeQrE + gTimeQrL, 0);
   gSum += vDataSep + DoubleToStr(((gTimeQrE + gTimeQrL ) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeQrEP + gTimeQrLP, 2) + " " + gCurrency;
   if      (gTimeQrEP + gTimeQrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good scalping strategy )"; }
   else if (gTimeQrEP + gTimeQrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad scalping strategy )"; }
   else                                { gSum += vDataSep + ""; gSum += vDataSep + ""; }
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
   gSum += vDataSep + DoubleToStr(gTimeDTrE, 0);
   gSum += vDataSep + DoubleToStr((gTimeDTrE / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeDTrEP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for day-traders )";
   gSum += vDataSep + "Day-trading orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gTimeDTrL, 0);
   gSum += vDataSep + DoubleToStr((gTimeDTrL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeDTrLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for day-traders )";
   gSum += vDataSep + "Day-trading orders with loss ( profit < 0 ).";

   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gTimeDTrE + gTimeDTrL, 0);
   gSum += vDataSep + DoubleToStr(((gTimeDTrE + gTimeDTrL) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeDTrEP + gTimeDTrLP, 2) + " " + gCurrency;
   if      (gTimeDTrEP + gTimeDTrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good day-trading strategy )"; }
   else if (gTimeDTrEP + gTimeDTrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad day-trading strategy )"; }
   else                                  { gSum += vDataSep + ""; gSum += vDataSep + ""; }
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
   gSum += vDataSep + DoubleToStr(gTimeIrE, 0);
   gSum += vDataSep + DoubleToStr((gTimeIrE / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeIrEP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( good for investors )";
   gSum += vDataSep + "Long-time orders with earn ( profit > 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gTimeIrL, 0);
   gSum += vDataSep + DoubleToStr((gTimeIrL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeIrLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( not good for investors )";
   gSum += vDataSep + "Long-time orders with loss ( profit < 0 ).";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gTimeIrE + gTimeIrL, 0);
   gSum += vDataSep + DoubleToStr(((gTimeIrE + gTimeIrL) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gTimeIrEP + gTimeIrLP, 2) + " " + gCurrency;
   if      (gTimeIrEP + gTimeIrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good long-term strategy )"; } 
   else if (gTimeIrEP + gTimeIrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad long-term strategy )"; }
   else                                { gSum += vDataSep + ""; gSum += vDataSep + ""; }
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
      gSum += vDataSep + DoubleToStr(gTypeHrE, 0);
      gSum += vDataSep + DoubleToStr((gTypeHrE / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeHrEP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( good for hedging )";
      gSum += vDataSep + "Hedging orders with earn ( profit > 0 ).";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypeHrL, 0);
      gSum += vDataSep + DoubleToStr((gTypeHrL / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeHrLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( not good for hedging )";
      gSum += vDataSep + "Hedging orders with loss ( profit < 0 ).";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gTypeHrE + gTypeHrL, 0);
      gSum += vDataSep + DoubleToStr(((gTypeHrE + gTypeHrL) / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeHrEP + gTypeHrLP, 2) + " " + gCurrency;
      if      (gTypeHrEP + gTypeHrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good hedging strategy )"; } 
      else if (gTypeHrEP + gTypeHrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad hedging strategy )"; }
      else                                { gSum += vDataSep + ""; gSum += vDataSep + ""; }
      gSum += vDataSep + "All hedging orders.";

      // pending stop

      gSum += vDataSep + "Pending stop :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";

      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypePSrE, 0);
      gSum += vDataSep + DoubleToStr((gTypePSrE / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePSrEP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( good for pending stop )";
      gSum += vDataSep + "Pending stop orders with earn ( profit > 0 ).";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypePSrL, 0);
      gSum += vDataSep + DoubleToStr((gTypePSrL / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePSrLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( not good for pending stop )";
      gSum += vDataSep + "Pending stop orders with loss ( profit < 0 ).";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gTypePSrE + gTypePSrL, 0);
      gSum += vDataSep + DoubleToStr(((gTypePSrE + gTypePSrL) / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePSrEP + gTypePSrLP, 2) + " " + gCurrency;
      if      (gTypePSrEP + gTypePSrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good pending stop strategy )"; } 
      else if (gTypePSrEP + gTypePSrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad pending stop strategy )"; }
      else                                  { gSum += vDataSep + ""; gSum += vDataSep + ""; }
      gSum += vDataSep + "All pending stop orders.";

      // pending limit

      gSum += vDataSep + "Pending limit :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";

      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypePLrE, 0);
      gSum += vDataSep + DoubleToStr((gTypePLrE / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePLrEP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( good for pending limit )";
      gSum += vDataSep + "Pending limit orders with earn ( profit > 0 ).";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypePLrL, 0);
      gSum += vDataSep + DoubleToStr((gTypePLrL / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePLrLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( not good for pending limit )";
      gSum += vDataSep + "Pending limit orders with loss ( profit < 0 ).";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gTypePLrE + gTypePLrL, 0);
      gSum += vDataSep + DoubleToStr(((gTypePLrE + gTypePLrL) / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypePLrEP + gTypePLrLP, 2) + " " + gCurrency;
      if      (gTypePLrEP + gTypePLrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good pending limit strategy )"; } 
      else if (gTypePLrEP + gTypePLrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad pending limit strategy )"; }
      else                                  { gSum += vDataSep + ""; gSum += vDataSep + ""; }
      gSum += vDataSep + "All pending limit orders.";

      // instant orders

      gSum += vDataSep + "Instant orders :";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";
      gSum += vDataSep + "";

      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypeIrE, 0);
      gSum += vDataSep + DoubleToStr((gTypeIrE / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeIrEP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( good for instant orders )";
      gSum += vDataSep + "Instant orders with earn ( profit > 0 ).";
      
      gSum += vDataSep + "";
      gSum += vDataSep + DoubleToStr(gTypeIrL, 0);
      gSum += vDataSep + DoubleToStr((gTypeIrL / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeIrLP, 2) + " " + gCurrency;
      gSum += vDataSep + "-";
      gSum += vDataSep + "( not good for instant orders )";
      gSum += vDataSep + "Instant orders with loss ( profit < 0 ).";
      
      gSum += vDataSep + "=";
      gSum += vDataSep + DoubleToStr(gTypeIrE + gTypeIrL, 0);
      gSum += vDataSep + DoubleToStr(((gTypeIrE + gTypeIrL) / gActivated) * 100, 1) + " %";
      gSum += vDataSep + DoubleToStr(gTypeIrEP + gTypeIrLP, 2) + " " + gCurrency;
      if      (gTypeIrEP + gTypeIrLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good instant strategy )"; } 
      else if (gTypeIrEP + gTypeIrLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad instant strategy )"; }
      else                                { gSum += vDataSep + ""; gSum += vDataSep + ""; }
      gSum += vDataSep + "All instant orders.";
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
   gSum += vDataSep + DoubleToStr(gNTPSL, 0);
   gSum += vDataSep + DoubleToStr((gNTPSL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gNTPSLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "";
   gSum += vDataSep + "All orders closed by trader without SL or TP.";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr((gActivated - gClosedB), 0);
   gSum += vDataSep + DoubleToStr(((gActivated - gClosedB) / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr((gActivatedP - gClosedBP), 2) + " " + gCurrency;
   if      (gActivatedP - gClosedBP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good trader strategy )"; } 
   else if (gActivatedP - gClosedBP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad trader strategy )"; }
   else                                  { gSum += vDataSep + ""; gSum += vDataSep + ""; }
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
   gSum += vDataSep + DoubleToStr(gClosedB, 0);
   gSum += vDataSep + DoubleToStr((gClosedB / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gClosedBP, 2) + " " + gCurrency;
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
   gSum += vDataSep + DoubleToStr(gSTPSL, 0);
   gSum += vDataSep + DoubleToStr((gSTPSL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gSTPSLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( secure strategy )";
   gSum += vDataSep + "All realized orders with SL or TP.";
   
   gSum += vDataSep + "";
   gSum += vDataSep + DoubleToStr(gNTPSL, 0);
   gSum += vDataSep + DoubleToStr((gNTPSL / gActivated) * 100, 1) + " %";
   gSum += vDataSep + DoubleToStr(gNTPSLP, 2) + " " + gCurrency;
   gSum += vDataSep + "-";
   gSum += vDataSep + "( risky strategy )";
   gSum += vDataSep + "All realized orders without SL or TP.";
   
   gSum += vDataSep + "=";
   gSum += vDataSep + DoubleToStr(gActivated, 0);
   gSum += vDataSep + "100 %";
   gSum += vDataSep + DoubleToStr(gActivatedP, 2) + " " + gCurrency;
   if      (gSTPSLP + gNTPSLP > 0) { gSum += vDataSep + vEarn; gSum += vDataSep + "( good general approach )"; } 
   else if (gSTPSLP + gNTPSLP < 0) { gSum += vDataSep + vLoss; gSum += vDataSep + "( bad general approach )"; }
   else                            { gSum += vDataSep + ""; gSum += vDataSep + ""; }
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
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
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
                  vOSlipV = (gPointVal * (vCSlip - gOSlipAbs)); gOSCBLV += vOSlipV;
                  gIssue += "=> earn: " + DoubleToStr(vOSlipV, 2) + " " + gCurrency;
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
   if (OrderTakeProfit() == 0 && OrderStopLoss() >  0) { gSTPSL++; gSTPSLP += OrderProfit() + OrderSwap(); }
   if (OrderTakeProfit() >  0 && OrderStopLoss() == 0) { gSTPSL++; gSTPSLP += OrderProfit() + OrderSwap(); }
   if (OrderTakeProfit() >  0 && OrderStopLoss() >  0) { gSTPSL++; gSTPSLP += OrderProfit() + OrderSwap(); }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed without set TP and SL price
// -----------------------------------------------------------------------------------------------------------------------

void getWithNotSet() 
{
   if (OrderTakeProfit() == 0 && OrderStopLoss() == 0) { gNTPSL++; gNTPSLP += OrderProfit() + OrderSwap(); }
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
         gTimeQrE++; gTimeQrEP += OrderProfit() + OrderSwap();
         gIssue = "Quick, " + gIssue; gShow = 1; 
      }
      if (OrderProfit() < 0) 
      { 
         gTimeQrL++; gTimeQrLP += OrderProfit() + OrderSwap();
         gIssue = "Quick, " + gIssue; gShow = 1;
      }
   }
   else if (vT.year == 1970 && vT.mon == 1 && vT.day == 1) {
   
      if (OrderProfit() > 0) 
      { 
         gTimeDTrE++; gTimeDTrEP += OrderProfit() + OrderSwap();
         gIssue = "Day-trade, " + gIssue;
      }
      if (OrderProfit() < 0) 
      { 
         gTimeDTrL++; gTimeDTrLP += OrderProfit() + OrderSwap();
         gIssue = "Day-trade, " + gIssue;
      }
   }
   else 
   {
      if (OrderProfit() > 0) 
      { 
         gTimeIrE++; gTimeIrEP += OrderProfit() + OrderSwap();
         gIssue = "Investing, " + gIssue;
      }
      if (OrderProfit() < 0) 
      { 
         gTimeIrL++; gTimeIrLP += OrderProfit() + OrderSwap();
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
   
   if (!gIsOpenFeature) { return; } // exit if open feature not available in comment
   
   k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt);
   
   vOrderType = (string)kExt[5]; 
   if ( StringFind(vOrderType, "H", 0) != -1 ) 
   {
      if (OrderProfit() > 0) { gTypeHrE++; gTypeHrEP += OrderProfit() + OrderSwap(); }
      if (OrderProfit() < 0) { gTypeHrL++; gTypeHrLP += OrderProfit() + OrderSwap(); }
   } 
}

// -----------------------------------------------------------------------------------------------------------------------
// Get pending stop orders
// -----------------------------------------------------------------------------------------------------------------------

void getPendingStop() 
{
   string k = "", kExt[];
   string vOrderType = "";
   
   if (!gIsOpenFeature) { return; } // exit if open feature not available in comment

   k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt);
   
   vOrderType = (string)kExt[5]; 
   if ( StringFind(vOrderType, "PS", 0) != -1 ) 
   {
      if (OrderProfit() > 0) { gTypePSrE++; gTypePSrEP += OrderProfit() + OrderSwap(); }
      if (OrderProfit() < 0) { gTypePSrL++; gTypePSrLP += OrderProfit() + OrderSwap(); }
   } 
}

// -----------------------------------------------------------------------------------------------------------------------
// Get pending limit orders
// -----------------------------------------------------------------------------------------------------------------------

void getPendingLimit() 
{
   string k = "", kExt[];
   string vOrderType = "";
   
   if (!gIsOpenFeature) { return; } // exit if open feature not available in comment
   
   k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt);
   
   vOrderType = (string)kExt[5]; 
   if ( StringFind(vOrderType, "PL", 0) != -1 ) 
   {
      if (OrderProfit() > 0) { gTypePLrE++; gTypePLrEP += OrderProfit() + OrderSwap(); }
      if (OrderProfit() < 0) { gTypePLrL++; gTypePLrLP += OrderProfit() + OrderSwap(); }
   } 
}

// -----------------------------------------------------------------------------------------------------------------------
// Get Instant Execution orders
// -----------------------------------------------------------------------------------------------------------------------

void getInstant() 
{
   string k = "", kExt[];
   string vOrderType = "";
   
   if (!gIsOpenFeature) { return; } // exit if open feature not available in comment
   
   k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt);
   
   vOrderType = (string)kExt[5]; 
   if ( StringFind(vOrderType, "I", 0) != -1 ) 
   {
      if (OrderProfit() > 0) { gTypeIrE++; gTypeIrEP += OrderProfit() + OrderSwap(); }
      if (OrderProfit() < 0) { gTypeIrL++; gTypeIrLP += OrderProfit() + OrderSwap(); }
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

   if (!gIsOpenFeature) { return; } // exit if open feature not available in comment
   
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
      gClosedB++; 
      gClosedBP += OrderProfit() + OrderSwap(); 
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
         getPendingStop();                                 // pending stop orders
         getPendingLimit();                                // pending limit orders
         getInstant();                                     // instant orders
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
