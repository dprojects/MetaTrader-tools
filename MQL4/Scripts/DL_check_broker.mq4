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

// Generate HTML output

bool sHTML = true;

// separator - left padding

string sCol = " | ";

// separator - entry

string sCSV = ";";      // for CSV converters

// -----------------------------------------------------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------------------------------------------------

string gHTML = "";

// -----------------------------------------------------------------------------------------------------------------------
// Show final summary in log
// -----------------------------------------------------------------------------------------------------------------------

void showSummary(string& inS[])
{

   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );

   for (int i=39; i>0; i-=3)
   {
      PrintFormat("%s %s %s %s %s %s %s", sCol, sCSV, inS[i-2], sCSV, inS[i-1], sCSV, inS[i] );
   }

   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );

   Print(sCol+inS[0]);

   Print(   sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------"
   );
}

// -----------------------------------------------------------------------------------------------------------------------
// Set HTML summary
// -----------------------------------------------------------------------------------------------------------------------

string setSummaryHTML(string& inS[])
{
   string vHTMLr = "";

   vHTMLr += inS[0]+"\n";

      vHTMLr += "<table>"+"\n";
         
         for (int i=1; i<40; i+=3)
         {
            vHTMLr += "<tr>";
               vHTMLr += "<td class=\"right\">"+inS[i]+"</td>";
               vHTMLr += "<td>"+inS[i+1]+"</td>";
               vHTMLr += "<td>"+inS[i+2]+"</td>";
            vHTMLr += "</tr>"+"\n";
         }

      vHTMLr += "</table>"+"\n";

   return vHTMLr;
}

// -----------------------------------------------------------------------------------------------------------------------
// Create HTML page
// -----------------------------------------------------------------------------------------------------------------------

void setHTMLPage(string inHTMLr, string inHTML)
{
   string vHTML = "";

   vHTML += "<!DOCTYPE html>"+"\n";
   vHTML += "<html>"+"\n";
      vHTML += "<head>"+"\n";
         vHTML += "<title>"+(string)AccountNumber()+", "+(string)AccountCompany()+"</title>"+"\n";
      vHTML += "<body>"+"\n";
   
         vHTML += "<style>"+"\n";
            vHTML += ".box-page { width: 100%; }"+"\n";
            vHTML += "table { width: auto; margin: 60px 0px; }"+"\n";
            vHTML += "td { padding: 5px 15px 5px 15px; border-top: 1px dotted red; }"+"\n";
            vHTML += ".right { text-align: right; }"+"\n";
         vHTML += "</style>\n";
   
         vHTML += "<div class=\"box-page\">";

            vHTML += "<h1>Account: "+(string)AccountNumber()+", "+(string)AccountCompany()+"</h1>"+"\n";
            vHTML += "</br></br>"+"\n";
   
            vHTML += inHTMLr;

            vHTML += "<table>"+"\n";
               vHTML += "<thead>"+"\n";
                  vHTML += "<tr>";
                     vHTML += "<th><b>Symbol</b></td>";
                     vHTML += "<th><b>Ticket</b></td>";
                     vHTML += "<th><b>Open time</b></td>";
                     vHTML += "<th><b>Closed time</b></td>";
                     vHTML += "<th class=\"right\"><b>Open price</b></td>";
                     vHTML += "<th class=\"right\"><b>Closed price</b></td>";
                     vHTML += "<th class=\"right\"><b>TP price</b></td>";
                     vHTML += "<th class=\"right\"><b>SL price</b></td>";
                     vHTML += "<th><b>Comment</b></td>";
                     vHTML += "<th><b>Type</b></td>";
                     vHTML += "<th class=\"right\"><b>TP points</b></td>";
                     vHTML += "<th class=\"right\"><b>SL points</b></td>";
                     vHTML += "<th class=\"right\"><b>Profit</b></td>";
                     vHTML += "<th><b>Issue</b></td>";
                  vHTML += "</tr>"+"\n";
               vHTML += "</thead>"+"\n";
               vHTML += "<tbody>"+"\n";
      
                  vHTML += inHTML;
   
               vHTML += "</tbody>"+"\n";
               vHTML += "</table>"+"\n";
   
            vHTML += "Report generated by: ";
            vHTML += "<a href=\"https://github.com/dprojects/MetaTrader-tools/blob/master/MQL4/Scripts/DL_check_broker.mq4\">";
            vHTML += "DL_check_broker.mq4";
            vHTML += "</a>"+"\n";
            vHTML += "</br></br>"+"\n";

         vHTML += "</div>"+"\n";
      vHTML += "</body>"+"\n";
   vHTML += "</html>"+"\n";

   gHTML = vHTML;
}

// -----------------------------------------------------------------------------------------------------------------------
// Save HTML output to file
// -----------------------------------------------------------------------------------------------------------------------

void setFile() 
{
   int    vFile = 0;
   string vFileName = (string)AccountNumber()+".html";
   string vFileDir = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files\\";
   
   vFile = FileOpen(vFileName, FILE_WRITE | FILE_TXT);
   
   if (vFile != INVALID_HANDLE)
   {
      FileWrite(vFile, gHTML);
      FileClose(vFile);
      
      Print(sCol+"The HTML report has been created at:"+vFileDir+vFileName);
   }
   else 
   {
      Print("File open failed, error ",GetLastError());
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// MAIN
// -----------------------------------------------------------------------------------------------------------------------

void OnStart()
{
   // variables

   bool   vOpen = false;
   int    vTotal = OrdersHistoryTotal();
   int    vShow = 0, vDigits = 0;
   double vDiff = 0, vPoint = 0, vTP = 0, vSL = 0;
   double vE = 0, vEqSL = 0, vEqSLME = 0, vSetSL = 0, vEQuick = 0;
   double vL = 0, vEqTP = 0, vEqTPME = 0, vSetTP = 0, vLQuick = 0;
   double vAll = 0, vSet = 0, vNotSet = 0, vO = 0, vCb = 0, vRg = 0;
   string vIssue = "", t1 = "";
   string k = "", kExt[], result = "", vHTML = "", vHTMLr = "", vSum[40];

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
         
         // Open price slip feature.
         // In fact you can't predict if the different open price will be good or bad 
         // in the future (this is how asymetric deviation prevents cheats).      
         
         k = OrderComment();
         
         if (StringFind(k, ";", 0) > 0) { 
          
               vOpen = true;
               StringSplit(k, StringGetCharacter(";",0), kExt);
               
               if (OrderOpenPrice() != (double)kExt[1]) { vIssue += "OPEN"; vO++; vShow = 1; }               
         }

         // all orders
         vAll++;
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
       
         if (sHTML)
         {
            vHTML += "<tr>";
               vHTML += "<td>"+(string)OrderSymbol()+"</td>";
               vHTML += "<td>"+(string)OrderTicket()+"</td>";
               vHTML += "<td>"+(string)OrderOpenTime()+"</td>";
               vHTML += "<td>"+(string)OrderCloseTime()+"</td>";
               vHTML += "<td class=\"right\">"+(string)OrderOpenPrice()+"</td>";
               vHTML += "<td class=\"right\">"+(string)OrderClosePrice()+"</td>";
               vHTML += "<td class=\"right\">"+(string)OrderTakeProfit()+"</td>";
               vHTML += "<td class=\"right\">"+(string)OrderStopLoss()+"</td>";
               vHTML += "<td>"+(string)OrderComment()+"</td>";
               vHTML += "<td>"+t1+"</td>";
               vHTML += "<td class=\"right\">"+(string)vTP+"</td>";
               vHTML += "<td class=\"right\">"+(string)vSL+"</td>";
               vHTML += "<td class=\"right\">"+DoubleToString(OrderProfit(), 2)+"</td>";
               vHTML += "<td>"+vIssue+"</td>";
            vHTML += "</tr>"+"\n";
         }

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
 
   // set summary
   
   vSum[0] = "Final result for Broker: "+result;
   
   vSum[1] = (string)vE;
   vSum[2] = "(good broker)";
   vSum[3] = "Orders closed by broker with bigger TakeProfit (better for trader)";
   
   vSum[4] = (string)vL;
   vSum[5] = "(bad broker)";
   vSum[6] = "Orders closed by broker with bigger StopLoss (worse for trader)";

   vSum[7] = (string)vEqTP;
   vSum[8] = "(good broker)";
   vSum[9] = "Orders closed by broker with TakeProfit expected by trader";

   vSum[10] = (string)vEqSL;
   vSum[11] = "(good broker)";
   vSum[12] = "Orders closed by broker with StopLoss expected by trader";

   vSum[13] = (string)vCb;
   vSum[14] = "(secure strategy)";
   vSum[15] = "All orders with set StopLoss or TakeProfit closed by broker";

   vSum[16] = (string)vEqTPME;
   vSum[17] = "(bad strategy)";
   vSum[18] = "Orders closed by trader before TakeProfit activation (cut profit)";

   vSum[19] = (string)vEqSLME;
   vSum[20] = "(good strategy)";
   vSum[21] = "Orders closed by trader before StopLoss activation (cut loss)";

   vSum[22] = (string)vSet;
   vSum[23] = "";
   vSum[24] = "Orders with set StopLoss or TakeProfit";

   vSum[25] = (string)vNotSet;
   vSum[26] = "(risky strategy)";
   vSum[27] = "Orders without set StopLoss or TakeProfit";

   if (vOpen) 
   {
      vSum[28] = (string)vO;
      vSum[29] = "(not very liquid market)";
      vSum[30] = "Orders opened by broker with different open price";
   }
   else
   {
      vSum[28] = "-";
      vSum[29] = "";
      vSum[30] = "To use open price slips feature you need to have for each order exact ";
      vSum[30] += "comment format e.g. ;requested_open_price; to compare with OrderOpenPrice() later.";
   }

   vSum[31] = (string)vEQuick;
   vSum[32] = "(good for scalpers & robots)";
   vSum[33] = "Quick orders with earn (profit > 0)";

   vSum[34] = (string)vLQuick;
   vSum[35] = "(not good for scalpers & robots)";
   vSum[36] = "Quick orders with loss (profit < 0)";

   vSum[37] = (string)vAll;
   vSum[38] = "";
   vSum[39] = "All orders (realized except cancelled and pending)";

   // show summary in log
   showSummary(vSum);
   
   // save HTML output to file 
   if (sHTML)
   { 
      vHTMLr = setSummaryHTML(vSum);
      setHTMLPage(vHTMLr, vHTML);
      setFile();
   }
}
