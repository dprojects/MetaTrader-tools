/* -----------------------------------------------------------------------------------------------------------------------

   2020, This tool has been made to check broker slips (cheats) or confirm the broker is honest (yes this can happen)

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
   double vE = 0, vEqSL = 0, vEqSLME = 0, vSetSL = 0, vEO = 0;
   double vL = 0, vEqTP = 0, vEqTPME = 0, vSetTP = 0, vLO = 0;
   double vAll = 0, vSet = 0, vNotSet = 0;
   string vType = "", t1 = "", t2 = "", t3 = "";
   string k = "", kExt[];
   
   // This is extended part to show incorrect broker open price (open slip).
   // But first for each order you have to set exact comment 
   // format like this: ";requestopenprice;slippage;ordertype;"
   // The requested open price must be 2nd from the left. 
   // First is empty for broker add.   
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
               if (OrderOpenPrice() < (double)kExt[1] && OrderType() == OP_BUY) { vType = "OPEN"; vEO++; print = 1; }
               if (OrderOpenPrice() > (double)kExt[1] && OrderType() == OP_BUY) { vType = "OPEN"; vLO++; print = 1; }
               if (OrderOpenPrice() < (double)kExt[1] && OrderType() == OP_SELL) { vType = "OPEN"; vEO++; print = 1; }
               if (OrderOpenPrice() > (double)kExt[1] && OrderType() == OP_SELL) { vType = "OPEN"; vLO++; print = 1; }
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
   

   PrintFormat(" %-85s %+10s ",
                  sCol + sCSV + "All orders (realized except cancelled and pending)", 
                  sCSV + (string)vAll
   );
   if (extFormat) {
      PrintFormat(" %-89s %+10s ",
                     sCol + sCSV + "BAD" + sCSV + "Orders opened by broker with client loss",
                     sCSV + (string)vLO
      );
      PrintFormat(" %-89s %+10s ",
                     sCol + sCSV + "GOOD" + sCSV + "Orders opened by broker with client earn",
                     sCSV + (string)vEO
      );
   }
   PrintFormat(" %-89s %+10s ",
                  sCol + sCSV + "Orders without set StopLoss or TakeProfit",
                  sCSV + (string)vNotSet
   );
   PrintFormat(" %-92s %+10s ",
                  sCol + sCSV + "Orders with set StopLoss or TakeProfit",
                  sCSV + (string)vSet
   );
   PrintFormat(" %-76s %+10s ",
                  sCol + sCSV + "Orders closed by trader before StopLoss activation (cut loss)",
                  sCSV + (string)vEqSLME
   );
   PrintFormat(" %-75s %+10s ",
                  sCol + sCSV + "Orders closed by trader before TakeProfit activation (cut profit)",
                  sCSV + (string)vEqTPME
   );
   PrintFormat(" %-78s %+10s ",
                  sCol + sCSV + "Orders closed by broker with set StopLoss or TakeProfit",
                  sCSV + (string)(vE + vL + vEqTP + vEqSL)
   );
   PrintFormat(" %-76s %+10s ",
                  sCol + sCSV + "GOOD" + sCSV + "Orders closed by broker with StopLoss expected by trader",
                  sCSV + (string)vEqSL
   );
   PrintFormat(" %-75s %+10s ",
                  sCol + sCSV + "GOOD" + sCSV + "Orders closed by broker with TakeProfit expected by trader",
                  sCSV + (string)vEqTP
   );
   PrintFormat(" %-72s %+10s ",
                  sCol + sCSV + "BAD" + sCSV + "Orders closed by broker with bigger StopLoss (worse for trader)",
                  sCSV + (string)vL
   );
   PrintFormat(" %-67s %+10s ",
                  sCol + sCSV + "GOOD" + sCSV + "Orders closed by broker with bigger TakeProfit (better for trader)",
                  sCSV + (string)vE
   );
   
   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );
}
