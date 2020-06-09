/* -----------------------------------------------------------------------------------------------------------------------

   2020, This tool shows SL, TP and Open price slips made by broker.  

   -------------------------------------------------------------------------------------------------------------------- */

#property copyright "Darek L"
#property link      "https://github.com/dprojects"
#property version   "20.20"
#property strict

#include <stdlib.mqh>
#include <WinUser32.mqh>


void OnStart()
{
   // variables

   int    vTotal = OrdersHistoryTotal();
   int    print = 0;
   double vE = 0, vEqSL = 0, vEqSLME = 0, vSetSL = 0;
   double vL = 0, vEqTP = 0, vEqTPME = 0, vSetTP = 0;
   double vAll = 0, vSet = 0, vNotSet = 0, vO = 0;
   string vType = "", t1 = "", t2 = "", t3 = "";
   string k = "", kExt[];
   
   // This is extended part to show incorrect broker open price (open slip).
   // But first for each order you have to set exact comment format
   // e.g. like this: ";requestopenprice;slippage;sliptry;pointvalue;ordertype;"
   // The comment format can be only "";requestopenprice;" but open price must be 
   // 2nd from the left. This need to have ";" separator on each side for broker add.
   bool   extFormat = true;

   // separators
   //string sCSV = ";"; // for CSV converters
   string sCSV = "   |   ";   // for better log look
   //string sCol = " | ";
   string sCol = "";

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
      
      print = 0;
      
      if (OrderType() == OP_BUY)
      {    
         // LOSS: bigger SL (SL slip)
         if (OrderStopLoss() > 0 && OrderClosePrice() < OrderStopLoss())
         { 
            vL++; print = 1; vType = "SL";
         }
         
         // EARN: bigger TP (TP slip)
         if (OrderTakeProfit() > 0 && OrderClosePrice() > OrderTakeProfit())
         { 
            vE++; print = 1; vType = "TP";
         }

         // EARN: smaller SL (faster closed SL)
         if (   OrderStopLoss() > 0 && 
                OrderClosePrice() < OrderOpenPrice() && 
                OrderClosePrice() > OrderStopLoss()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[sl]", 0) >   0) { vE++; print = 1; vType = "SL"; }
            if (StringFind(k, "[sl]", 0) == -1) { vEqSLME++; vType = "SL"; }
         }
         
         // LOSS: smaller TP (faster closed TP)
         if (   OrderTakeProfit() > 0 && 
                OrderClosePrice() > OrderOpenPrice() && 
                OrderClosePrice() < OrderTakeProfit()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[tp]", 0) >   0) { vL++; print = 1; vType = "TP"; }
            if (StringFind(k, "[tp]", 0) == -1) { vEqTPME++; vType = "TP"; }
         }
      }
       
      if (OrderType() == OP_SELL)
      {  
         // LOSS: bigger SL (SL slip)      
         if (OrderStopLoss() > 0 && OrderClosePrice() > OrderStopLoss())
         { 
            vL++; print = 1; vType = "SL";
         }
         
         // EARN: bigger TP (TP slip)
         if (OrderTakeProfit() > 0 && OrderClosePrice() < OrderTakeProfit())
         { 
            vE++; print = 1; vType = "TP";
         }

         // EARN: smaller SL (faster closed SL)
         if (   OrderStopLoss() > 0 && 
                OrderClosePrice() > OrderOpenPrice() && 
                OrderClosePrice() < OrderStopLoss()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[sl]", 0) >   0) { vE++; print = 1; vType = "SL"; }
            if (StringFind(k, "[sl]", 0) == -1) { vEqSLME++; vType = "SL"; }
         }
         
         // LOSS: smaller TP (faster closed TP)
         if (   OrderTakeProfit() > 0 && 
                OrderClosePrice() < OrderOpenPrice() && 
                OrderClosePrice() > OrderTakeProfit()
            )
         {
            k = OrderComment();
            if (StringFind(k, "[tp]", 0) >   0) { vL++; print = 1; vType = "TP"; }
            if (StringFind(k, "[tp]", 0) == -1) { vEqTPME++; vType = "TP"; }
         }
      }

      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
         if (OrderTakeProfit() == OrderClosePrice()) { vEqTP++; }
         if (OrderStopLoss()   == OrderClosePrice()) { vEqSL++; }
         if (OrderTakeProfit() == 0 && OrderStopLoss() == 0) { vNotSet++; }
         if (OrderTakeProfit() == 0 && OrderStopLoss() >  0) { vSet++; }
         if (OrderTakeProfit() >  0 && OrderStopLoss() == 0) { vSet++; }
         if (OrderTakeProfit() >  0 && OrderStopLoss() >  0) { vSet++; }
         vAll++;
      }
      
      if (extFormat) {
         if (OrderType() == OP_BUY || OrderType() == OP_SELL)
         {
            k = OrderComment();
            if (StringFind(k, ";", 0) > 0) { 
               StringSplit(k, StringGetCharacter(";",0), kExt);
               
               // In fact you can't tell if the different open price will be good or bad.
               // You have to decide on your own. You don't know the future, the broker also.
               // You can be sure only if you have faster data than broker but this means, 
               // you just trying to cheat broker.
               if (OrderOpenPrice() != (double)kExt[1]) { vType = "OPEN"; vO++; print = 1; }
            }
         }
      }

      if (print == 1)
      {

         if (OrderType() == OP_BUY)  { t1 = "BUY";  }
         if (OrderType() == OP_SELL) { t1 = "SELL"; }
         
         if (vType == "SL") { t2 = "SL"; t3 = (string)OrderStopLoss();   }
         if (vType == "TP") { t2 = "TP"; t3 = (string)OrderTakeProfit(); }
         if (vType == "OPEN") { t2 = "OPEN"; t3 = (string)OrderOpenPrice(); }

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
               "",
               sCol, sCSV, 
               (string)OrderSymbol(), sCSV, 
               (string)OrderTicket(), sCSV, 
               (string)OrderCloseTime(), sCSV, 
               t1, sCSV, 
               t2, sCSV,
               t3, sCSV,
               (string)OrderClosePrice(), sCSV, 
               (string)OrderComment(), sCSV, 
               (string)OrderProfit(), sCSV
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
               "",   
               sCol, sCSV, 
               "Symbol", sCSV, 
               "Ticket", sCSV, 
               "Closed time", sCSV,
               "Order type", sCSV,
               "Slip type", sCSV,
               "Slip price", sCSV,
               "Closed price", sCSV,
               "Comment", sCSV,
               "Profit", sCSV
   );

   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );
   

   PrintFormat("%s %s %-6s %s %s",
                  sCol, sCSV, 
                  (string)vAll, sCSV, 
                  "All orders (realized except cancelled and pending)"
   );
   
   if (extFormat) {
      
      PrintFormat("%s %s %-6s %s %s",
                     sCol, sCSV, 
                     (string)vO, sCSV, 
                     "Orders opened by broker with different open price"
      );
   }
   
   PrintFormat("%s %s %-6s %s %s",
                  sCol, sCSV, 
                  (string)vNotSet, sCSV, 
                  "Orders without set StopLoss or TakeProfit"
   );
   PrintFormat("%s %s %-6s %s %s",
                  sCol, sCSV, 
                  (string)vSet, sCSV, 
                  "Orders with set StopLoss or TakeProfit"
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqSLME, sCSV, 
                  "Good job", sCSV, 
                   "Orders closed by trader before StopLoss activation (cut loss)"
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqTPME, sCSV, 
                  "Bad strategy", sCSV, 
                  "Orders closed by trader before TakeProfit activation (cut profit)"
   );
   PrintFormat("%s %s %-6s %s %s",
                  sCol, sCSV, 
                  (string)(vE + vL + vEqTP + vEqSL), sCSV, 
                  "All orders closed by broker with set StopLoss or TakeProfit"            
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqSL, sCSV, 
                  "Good broker", sCSV, 
                  "Orders closed by broker with StopLoss expected by trader"
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vEqTP, sCSV, 
                  "Good broker", sCSV, 
                  "Orders closed by broker with TakeProfit expected by trader"
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vL, sCSV, 
                  "Bad broker", sCSV, 
                  "Orders closed by broker with bigger StopLoss (worse for trader)"
   );
   PrintFormat("%s %s %-6s %s %s %s %s",
                  sCol, sCSV, 
                  (string)vE, sCSV, 
                  "Good broker", sCSV, 
                  "Orders closed by broker with bigger TakeProfit (better for trader)"
   );
   
   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );
}
