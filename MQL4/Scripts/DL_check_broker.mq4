/* -----------------------------------------------------------------------------------------------------------------------

   2020, This tool shows SL, TP and Open price slips made by broker.  

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

// This is extended part to show incorrect broker open price (open slip).
// But first for each order you have to set exact comment format
// e.g. like this: ";requestopenprice;slippage;sliptry;pointvalue;ordertype;"
// The comment format can be only "";requestopenprice;" but open price must be 
// 2nd from the left. This need to have ";" separator on each side for broker add.

bool sOpen = true;

// separator - left padding
//string sCol = "";

string sCol = " | ";

// separator - entry

//string sCSV = "  ";   // for better log look
string sCSV = ";";      // for CSV converters

// -----------------------------------------------------------------------------------------------------------------------
// MAIN
// -----------------------------------------------------------------------------------------------------------------------

void OnStart()
{
   // variables

   int    vTotal = OrdersHistoryTotal();
   int    vShow = 0, vDigits = 0;
   double vDiff = 0, vPoint = 0, vTP = 0, vSL = 0;
   double vE = 0, vEqSL = 0, vEqSLME = 0, vSetSL = 0, vEQuick = 0;
   double vL = 0, vEqTP = 0, vEqTPME = 0, vSetTP = 0, vLQuick = 0;
   double vAll = 0, vSet = 0, vNotSet = 0, vO = 0, vCb = 0, vRg = 0;
   string vIssue = "", t1 = "";
   string k = "", kExt[], result = "";
   
   datetime vTime;
   MqlDateTime vT;
   
   // main
   
   Print("");
   Print("");
   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );

   if (vTotal == 0) { Print("ERROR: No orders found."); return; }
   
   for (int i=0; i<vTotal; i++) 
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
      
      // reset values for each order
      vShow = 0; vIssue = ""; vTP = 0; vSL = 0;

      // for old markets, need to open chart to load data to get it worked
      vPoint = MarketInfo(OrderSymbol(), MODE_POINT);
      
      // check only activated orders

      if (OrderType() == OP_BUY)
      {    
         // LOSS: bigger SL (SL slip)
         if (OrderStopLoss() > 0 && OrderClosePrice() < OrderStopLoss())
         { 
            vDiff = OrderStopLoss() - OrderClosePrice();
            if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

            vL++; vShow = 1; vIssue += "slip SL+"+(string)vDiff;
         }
         
         // EARN: bigger TP (TP slip)
         if (OrderTakeProfit() > 0 && OrderClosePrice() > OrderTakeProfit())
         { 
            vDiff = OrderClosePrice() - OrderTakeProfit(); 
            if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

            vE++; vShow = 1; vIssue += "slip TP+"+(string)vDiff;
         }

         // EARN: smaller SL (faster closed SL)
         if (   OrderStopLoss() > 0 && 
                OrderClosePrice() < OrderOpenPrice() && 
                OrderClosePrice() > OrderStopLoss()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[sl]", 0) >   0) 
            { 
               vDiff = OrderClosePrice() - OrderStopLoss(); 
               if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

               vE++; vShow = 1; vIssue += "slip SL-"+(string)vDiff;
            }
            if (StringFind(k, "[sl]", 0) == -1) { vEqSLME++; }
         }
         
         // LOSS: smaller TP (faster closed TP)
         if (   OrderTakeProfit() > 0 && 
                OrderClosePrice() > OrderOpenPrice() && 
                OrderClosePrice() < OrderTakeProfit()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[tp]", 0) >   0) 
            { 
               vDiff = OrderTakeProfit() - OrderClosePrice();
               if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

               vL++; vShow = 1; vIssue += "slip TP-"+(string)vDiff;
            }
            if (StringFind(k, "[tp]", 0) == -1) { vEqTPME++; }
         }
      }
       
      if (OrderType() == OP_SELL)
      {  
         // LOSS: bigger SL (SL slip)      
         if (OrderStopLoss() > 0 && OrderClosePrice() > OrderStopLoss())
         { 
            vDiff = OrderClosePrice() - OrderStopLoss();
            if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

            vL++; vShow = 1; vIssue += "slip SL+"+(string)vDiff;
         }
         
         // EARN: bigger TP (TP slip)
         if (OrderTakeProfit() > 0 && OrderClosePrice() < OrderTakeProfit())
         { 
            vDiff = OrderTakeProfit() - OrderClosePrice();
            if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

            vE++; vShow = 1; vIssue += "slip TP+"+(string)vDiff;
         }

         // EARN: smaller SL (faster closed SL)
         if (   OrderStopLoss() > 0 && 
                OrderClosePrice() > OrderOpenPrice() && 
                OrderClosePrice() < OrderStopLoss()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[sl]", 0) >   0) 
            { 
               vDiff = OrderStopLoss() - OrderClosePrice();
               if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

               vE++; vShow = 1; vIssue += "slip SL-"+(string)vDiff;
            }
            if (StringFind(k, "[sl]", 0) == -1) { vEqSLME++; }
         }
         
         // LOSS: smaller TP (faster closed TP)
         if (   OrderTakeProfit() > 0 && 
                OrderClosePrice() < OrderOpenPrice() && 
                OrderClosePrice() > OrderTakeProfit()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[tp]", 0) >   0) 
            { 
               vDiff = OrderClosePrice() - OrderTakeProfit();
               if (vPoint != 0) { vDiff = MathRound(vDiff / vPoint); }

               vL++; vShow = 1; vIssue += "slip TP-"+(string)vDiff;
            }
            if (StringFind(k, "[tp]", 0) == -1) { vEqTPME++; }
         }
      }

      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
         // closed by broker with correct TP & SL
         if (OrderTakeProfit() == OrderClosePrice()) { vEqTP++; }
         if (OrderStopLoss()   == OrderClosePrice()) { vEqSL++; }
         
         // set TP or SL
         if (OrderTakeProfit() == 0 && OrderStopLoss() >  0) { vSet++; }
         if (OrderTakeProfit() >  0 && OrderStopLoss() == 0) { vSet++; }
         if (OrderTakeProfit() >  0 && OrderStopLoss() >  0) { vSet++; }
         
         // not set SL & TP
         if (OrderTakeProfit() == 0 && OrderStopLoss() == 0) { vNotSet++; }

         // quick orders
   
         vTime = OrderCloseTime() - OrderOpenTime();
         TimeToStruct(vTime, vT);
         
         if (vT.year == 1970 && vT.mon == 1 && vT.day == 1 && vT.hour == 0 && vT.min == 0) {

            if (vT.sec < 3 && OrderProfit() > 0) { vIssue = "QUICK "+ vIssue; vEQuick++; vShow = 1; }
            if (vT.sec < 3 && OrderProfit() < 0) { vIssue = "QUICK "+ vIssue; vLQuick++; vShow = 1; }
         }
         
         // all orders
         vAll++;
      }
      
      if (sOpen) {
         if (OrderType() == OP_BUY || OrderType() == OP_SELL)
         {
            k = OrderComment();
            if (StringFind(k, ";", 0) > 0) { 
               StringSplit(k, StringGetCharacter(";",0), kExt);
               
               // In fact you can't tell if the different open price will be good or bad (asymetric deviation).
               // Broker don't know if the "worse" open price will not be better in long term, you change 
               // SL, TP. You can be sure only if you have faster data than broker but this means, 
               // you just trying to cheat broker. In fact this is good broker if cut off such people.
               if (OrderOpenPrice() != (double)kExt[1]) { vIssue += "OPEN"; vO++; vShow = 1; }
            }
         }
      }

      if (vShow == 1)
      {
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
         
         if (vPoint != 0) { 
            vTP = MathRound(vTP / vPoint);
            vSL = MathRound(vSL / vPoint);
         }

         // set table data rows
         PrintFormat("%s %s " + 
               "%s %s " + 
               "%s %s " + 
               "%s %s " + 
               "%s %s " +  
               "%s %s " + 
               "%s %s " +  
               "%s %s " + 
               "%s %s " + 
               "%s %s " + 
               "%s %s " +  
               "%s %s " + 
               "%s %s " +  
               "%s %s " + 
               "%s" + 
               "",
               sCol, sCSV, 
               (string)OrderSymbol(), sCSV, 
               (string)OrderTicket(), sCSV, 
               (string)OrderOpenTime(), sCSV, 
               (string)OrderCloseTime(), sCSV, 
               (string)OrderOpenPrice(), sCSV, 
               (string)OrderClosePrice(), sCSV, 
               (string)OrderTakeProfit(), sCSV,
               (string)OrderStopLoss(), sCSV,
               (string)OrderComment(), sCSV, 
               t1, sCSV, 
               (string)vTP, sCSV,
               (string)vSL, sCSV,
               DoubleToString(OrderProfit(), 2), sCSV,
               vIssue
         );
      }
   }
   
   // set table header
   PrintFormat("%s %s " + 
               "%s %s " + 
               "%s %s " + 
               "%s %s " +  
               "%s %s " +  
               "%s %s " +  
               "%s %s " +  
               "%s %s " +  
               "%s %s " +  
               "%s %s " +
               "%s %s " +  
               "%s %s " +
               "%s %s " +  
               "%s %s " +  
               "%s" +
               "",   
               sCol, sCSV, 
               "Symbol", sCSV, 
               "Ticket", sCSV, 
               "Open time", sCSV,
               "Closed time", sCSV,
               "Open price", sCSV,
               "Closed price", sCSV,
               "TP price", sCSV,
               "SL price", sCSV,
               "Comment", sCSV,
               "Type", sCSV,
               "TP points", sCSV,
               "SL points", sCSV,
               "Profit", sCSV,
               "Issue"
   );

   // calculate final result

   vCb = vE + vL + vEqTP + vEqSL;
   vRg = ( (vE + vEqTP + vEqSL) / vCb ) * 100;

   if (vRg > 80) { result = "VERY GOOD"; } 
   else if (vRg > 50) { result = "GOOD"; }
   else if (vRg > 20) { result = "BAD"; }
   else { result = "VERY BAD"; }

   result += "   ( " + DoubleToStr(vRg, 0) + "% ) ";
 
   // show final result

   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );
   

   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vAll, sCSV, 
                  "", sCSV, 
                  "All orders (realized except cancelled and pending)"
   );
   
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vLQuick, sCSV, 
                  "(not good for scalpers & robots)", sCSV, 
                  "Quick orders with loss (profit < 0)"
   );

   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEQuick, sCSV, 
                  "(good for scalpers & robots)", sCSV, 
                  "Quick orders with earn (profit > 0)"
   );

   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vAll, sCSV, 
                  "", sCSV, 
                  "All orders (realized except cancelled and pending)"
   );

   if (sOpen) {
      
      PrintFormat("%s %s %s %s %s %s %s",
                     sCol, sCSV, 
                     (string)vO, sCSV, 
                     "(not very liquid market)", sCSV, 
                     "Orders opened by broker with different open price"
      );
   }
   
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vNotSet, sCSV, 
                  "(risky strategy)", sCSV, 
                  "Orders without set StopLoss or TakeProfit"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vSet, sCSV, 
                  "", sCSV, 
                  "Orders with set StopLoss or TakeProfit"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqSLME, sCSV, 
                  "(good strategy)", sCSV, 
                   "Orders closed by trader before StopLoss activation (cut loss)"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqTPME, sCSV, 
                  "(bad strategy)", sCSV, 
                  "Orders closed by trader before TakeProfit activation (cut profit)"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vCb, sCSV, 
                  "(secure strategy)", sCSV, 
                  "All orders with set StopLoss or TakeProfit closed by broker"            
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqSL, sCSV, 
                  "(good broker)", sCSV, 
                  "Orders closed by broker with StopLoss expected by trader"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqTP, sCSV, 
                  "(good broker)", sCSV, 
                  "Orders closed by broker with TakeProfit expected by trader"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vL, sCSV, 
                  "(bad broker)", sCSV, 
                  "Orders closed by broker with bigger StopLoss (worse for trader)"
   );
   PrintFormat("%s %s %s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vE, sCSV, 
                  "(good broker)", sCSV, 
                  "Orders closed by broker with bigger TakeProfit (better for trader)"
   );
   
   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );

   PrintFormat("%s %s %s %s",
                  sCol, sCSV, 
                  "Final result for Broker: ",
                  result
   );
}
