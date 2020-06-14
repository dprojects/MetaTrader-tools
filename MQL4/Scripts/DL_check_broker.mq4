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

// generate HTML output
bool sHTML = true;

// separators
string sCSV = ";";      // entry, for CSV converters
string sCol = " | ";    // left padding
string sLine = sCol +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------" +
            "--------------------------------------------------------------------------------";

// -----------------------------------------------------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------------------------------------------------

bool   gOpen = false;
int    gShow = 0;
double gE = 0, gEqSL = 0, gEqSLME = 0, gSetSL = 0, gEQuick = 0;
double gL = 0, gEqTP = 0, gEqTPME = 0, gSetTP = 0, gLQuick = 0;
double gActivated = 0, gSet = 0, gNotSet = 0, gO = 0, gCb = 0, gRg = 0;
double gPoint = 0;
string gHTML = "", gHTMLe = "";
string gIssue = "";
string vSum[40];

// -----------------------------------------------------------------------------------------------------------------------
// Set final summary
// -----------------------------------------------------------------------------------------------------------------------

void setSummary()
{
   string result = "";

   // calculate

   gCb = gE + gL + gEqTP + gEqSL;
   gRg = ( (gE + gEqTP + gEqSL) / gCb ) * 100;

   if (gRg > 80) { result = "VERY GOOD"; } 
   else if (gRg > 50) { result = "GOOD"; }
   else if (gRg > 20) { result = "BAD"; }
   else { result = "VERY BAD"; }

   result += "   ( " + DoubleToStr(gRg, 0) + "% ) ";
 
   // set summary
   
   vSum[0] = "Final result for Broker: "+result;
   
   vSum[1] = (string)gE;
   vSum[2] = "(good broker)";
   vSum[3] = "Orders closed by broker with bigger TakeProfit (better for trader)";
   
   vSum[4] = (string)gL;
   vSum[5] = "(bad broker)";
   vSum[6] = "Orders closed by broker with bigger StopLoss (worse for trader)";

   vSum[7] = (string)gEqTP;
   vSum[8] = "(good broker)";
   vSum[9] = "Orders closed by broker with TakeProfit expected by trader";

   vSum[10] = (string)gEqSL;
   vSum[11] = "(good broker)";
   vSum[12] = "Orders closed by broker with StopLoss expected by trader";

   vSum[13] = (string)gCb;
   vSum[14] = "(secure strategy)";
   vSum[15] = "All orders with set StopLoss or TakeProfit closed by broker";

   vSum[16] = (string)gEqTPME;
   vSum[17] = "(bad strategy)";
   vSum[18] = "Orders closed by trader before TakeProfit activation (cut profit)";

   vSum[19] = (string)gEqSLME;
   vSum[20] = "(good strategy)";
   vSum[21] = "Orders closed by trader before StopLoss activation (cut loss)";

   vSum[22] = (string)gSet;
   vSum[23] = "";
   vSum[24] = "Orders with set StopLoss or TakeProfit";

   vSum[25] = (string)gNotSet;
   vSum[26] = "(risky strategy)";
   vSum[27] = "Orders without set StopLoss or TakeProfit";

   if (gOpen) 
   {
      vSum[28] = (string)gO;
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

   vSum[31] = (string)gEQuick;
   vSum[32] = "(good for scalpers & robots)";
   vSum[33] = "Quick orders with earn (profit > 0)";

   vSum[34] = (string)gLQuick;
   vSum[35] = "(not good for scalpers & robots)";
   vSum[36] = "Quick orders with loss (profit < 0)";

   vSum[37] = (string)gActivated;
   vSum[38] = "";
   vSum[39] = "All orders (realized except cancelled and pending)";
}

// -----------------------------------------------------------------------------------------------------------------------
// Show final summary in log
// -----------------------------------------------------------------------------------------------------------------------

void showSummary()
{
   // show table header
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

   Print(sLine);

   for (int i=39; i>0; i-=3)
   {
      PrintFormat("%s %s %s %s %s %s %s", sCol, sCSV, vSum[i-2], sCSV, vSum[i-1], sCSV, vSum[i] );
   }

   Print(sLine);
   Print(sCol + vSum[0]);
   Print(sLine);
}

// -----------------------------------------------------------------------------------------------------------------------
// Set entry with issue
// -----------------------------------------------------------------------------------------------------------------------

void setEntry()
{
   double vTP = 0, vSL = 0;
   string t1 = "";

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
         gIssue
   );
 
   if (sHTML)
   {
      gHTMLe += "<tr>";
         gHTMLe += "<td>"+(string)OrderSymbol()+"</td>";
         gHTMLe += "<td>"+(string)OrderTicket()+"</td>";
         gHTMLe += "<td>"+(string)OrderOpenTime()+"</td>";
         gHTMLe += "<td>"+(string)OrderCloseTime()+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)OrderOpenPrice()+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)OrderClosePrice()+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)OrderTakeProfit()+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)OrderStopLoss()+"</td>";
         gHTMLe += "<td>"+(string)OrderComment()+"</td>";
         gHTMLe += "<td>"+t1+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)vTP+"</td>";
         gHTMLe += "<td class=\"right\">"+(string)vSL+"</td>";
         gHTMLe += "<td class=\"right\">"+DoubleToString(OrderProfit(), 2)+"</td>";
         gHTMLe += "<td>"+gIssue+"</td>";
      gHTMLe += "</tr>"+"\n";
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Set summary in HTML format
// -----------------------------------------------------------------------------------------------------------------------

string setSummaryHTML()
{
   string vHTML = "";

   vHTML += vSum[0]+"\n";

      vHTML += "<table>"+"\n";
         
         for (int i=1; i<40; i+=3)
         {
            vHTML += "<tr>";
               vHTML += "<td class=\"right\">"+vSum[i]+"</td>";
               vHTML += "<td>"+vSum[i+1]+"</td>";
               vHTML += "<td>"+vSum[i+2]+"</td>";
            vHTML += "</tr>"+"\n";
         }

      vHTML += "</table>"+"\n";

   return vHTML;
}

// -----------------------------------------------------------------------------------------------------------------------
// Create HTML page
// -----------------------------------------------------------------------------------------------------------------------

void setHTMLPage()
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
   
            vHTML += setSummaryHTML();

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
      
                  vHTML += gHTMLe;
   
               vHTML += "</tbody>"+"\n";
               vHTML += "</table>"+"\n";
   
            vHTML += "Report generated by: ";
            vHTML += "<a href=\"https://github.com/dprojects/MetaTrader-tools/";
            vHTML += "blob/master/MQL4/Scripts/DL_check_broker.mq4\">DL_check_broker.mq4</a>"+"\n";
            vHTML += "</br></br>"+"\n";

         vHTML += "</div>"+"\n";
      vHTML += "</body>"+"\n";
   vHTML += "</html>"+"\n";

   gHTML = vHTML;
}

// -----------------------------------------------------------------------------------------------------------------------
// Save HTML output to file
// -----------------------------------------------------------------------------------------------------------------------

void setHTMLFile() 
{
   int    vFile = 0;
   string vFileName = (string)AccountNumber() + ".html";
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
// Get bigger TP or SL (closed too late)
// -----------------------------------------------------------------------------------------------------------------------

void getBigger() 
{
   double vDiff = 0;

   if (OrderType() == OP_BUY)
   {    
      // LOSS: bigger SL (SL slip)
      if (OrderStopLoss() > 0 && OrderClosePrice() < OrderStopLoss())
      { 
         vDiff = OrderStopLoss() - OrderClosePrice();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         gL++; gShow = 1; gIssue += "slip SL+"+(string)vDiff;
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() > OrderTakeProfit())
      { 
         vDiff = OrderClosePrice() - OrderTakeProfit(); 
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         gE++; gShow = 1; gIssue += "slip TP+"+(string)vDiff;
      }
   }
   
   if (OrderType() == OP_SELL)
   {  
      // LOSS: bigger SL (SL slip)      
      if (OrderStopLoss() > 0 && OrderClosePrice() > OrderStopLoss())
      { 
         vDiff = OrderClosePrice() - OrderStopLoss();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         gL++; gShow = 1; gIssue += "slip SL+"+(string)vDiff;
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() < OrderTakeProfit())
      { 
         vDiff = OrderTakeProfit() - OrderClosePrice();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         gE++; gShow = 1; gIssue += "slip TP+"+(string)vDiff;
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get smaller TP or SL (closed too fast)
// -----------------------------------------------------------------------------------------------------------------------

void getSmaller() 
{
   double vDiff = 0;
   string k = "";   

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
         if (StringFind(k, "[sl]", 0) >   0) 
         { 
            vDiff = OrderClosePrice() - OrderStopLoss(); 
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            gE++; gShow = 1; gIssue += "slip SL-"+(string)vDiff;
         }
         
         // closed by you
         if (StringFind(k, "[sl]", 0) == -1) { gEqSLME++; }
      }
      
      // LOSS: smaller TP (faster closed TP)
      if (   OrderTakeProfit() > 0 && 
             OrderClosePrice() > OrderOpenPrice() && 
             OrderClosePrice() < OrderTakeProfit()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[tp]", 0) >   0) 
         { 
            vDiff = OrderTakeProfit() - OrderClosePrice();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            gL++; gShow = 1; gIssue += "slip TP-"+(string)vDiff;
         }

         // closed by you
         if (StringFind(k, "[tp]", 0) == -1) { gEqTPME++; }
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
         if (StringFind(k, "[sl]", 0) >   0) 
         { 
            vDiff = OrderStopLoss() - OrderClosePrice();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            gE++; gShow = 1; gIssue += "slip SL-"+(string)vDiff;
         }

         // closed by you
         if (StringFind(k, "[sl]", 0) == -1) { gEqSLME++; }
      }
      
      // LOSS: smaller TP (faster closed TP)
      if (   OrderTakeProfit() > 0 && 
             OrderClosePrice() < OrderOpenPrice() && 
             OrderClosePrice() > OrderTakeProfit()
         )
      {
         k = OrderComment();

         // closed by broker
         if (StringFind(k, "[tp]", 0) >   0) 
         { 
            vDiff = OrderClosePrice() - OrderTakeProfit();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            gL++; gShow = 1; gIssue += "slip TP-"+(string)vDiff;
         }

         // closed by you
         if (StringFind(k, "[tp]", 0) == -1) { gEqTPME++; }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed with expected TP or SL price
// -----------------------------------------------------------------------------------------------------------------------

void getEqual() 
{
   if (OrderTakeProfit() == OrderClosePrice()) { gEqTP++; }
   if (OrderStopLoss()   == OrderClosePrice()) { gEqSL++; }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed with set TP or SL price
// -----------------------------------------------------------------------------------------------------------------------

void getWithSet() 
{
   if (OrderTakeProfit() == 0 && OrderStopLoss() >  0) { gSet++; }
   if (OrderTakeProfit() >  0 && OrderStopLoss() == 0) { gSet++; }
   if (OrderTakeProfit() >  0 && OrderStopLoss() >  0) { gSet++; }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed without set TP and SL price
// -----------------------------------------------------------------------------------------------------------------------

void getWithNotSet() 
{
   if (OrderTakeProfit() == 0 && OrderStopLoss() == 0) { gNotSet++; }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get quick orders 
// -----------------------------------------------------------------------------------------------------------------------

void getQuick() 
{
   datetime vTime;
   MqlDateTime vT;
   
   vTime = OrderCloseTime() - OrderOpenTime();
   TimeToStruct(vTime, vT);
   
   if (vT.year == 1970 && vT.mon == 1 && vT.day == 1 && vT.hour == 0 && vT.min == 0) {
   
      if (vT.sec < 3 && OrderProfit() > 0) { gIssue = "QUICK "+ gIssue; gEQuick++; gShow = 1; }
      if (vT.sec < 3 && OrderProfit() < 0) { gIssue = "QUICK "+ gIssue; gLQuick++; gShow = 1; }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders with open price slip. Open price slip feature.
// In fact you can't predict if the different open price will be good or bad 
// in the future (this is how asymetric deviation prevents cheats).      
// -----------------------------------------------------------------------------------------------------------------------

void getOpenSlip() 
{
   string k = "", kExt[];

   k = OrderComment();
   
   if (StringFind(k, ";", 0) > 0) { 
    
      gOpen = true;
      StringSplit(k, StringGetCharacter(";",0), kExt);
      
      if (OrderOpenPrice() != (double)kExt[1]) { gIssue += "OPEN"; gO++; gShow = 1; }               
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// MAIN
// -----------------------------------------------------------------------------------------------------------------------

void OnStart()
{
   int    vTotal = OrdersHistoryTotal();
   
   Print("");
   Print("");
   Print(sLine);

   if (vTotal == 0) { Print("ERROR: No orders found."); return; }

   for (int i=0; i<vTotal; i++) 
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
     
      // reset values for each order
      gShow = 0; gIssue = "";

      // for old markets, need to open chart to load data to get it worked
      gPoint = MarketInfo(OrderSymbol(), MODE_POINT);
      
      getBigger();         // bigger TP or SL
      getSmaller();        // smaller TP or SL

      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
         getEqual();       // with expected TP or SL price
         getWithSet();     // with set TP or SL
         getWithNotSet();  // with not set TP or SL
         getQuick();       // quick orders
         getOpenSlip();    // open slip
         
         gActivated++;     // all olders but only activated
      }
      if (gShow == 1) { setEntry(); }
   }
   
   setSummary();  // calculate final result
   showSummary(); // show summary in log
   
   // save HTML output to file 
   if (sHTML) { setHTMLFile(); }
}
