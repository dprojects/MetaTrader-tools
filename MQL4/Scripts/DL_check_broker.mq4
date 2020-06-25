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

int    gShow = 0;
bool   gHasOpen = false, gIsOpen = false;
double gBiggerTP = 0, gSLEqual = 0, gCutSLT = 0, gCutSLB = 0, gQuickEarn = 0, gOpenEarn = 0;
double gBiggerSL = 0, gTPEqual = 0, gCutTPT = 0, gCutTPB = 0, gQuickLoss = 0, gOpenLoss = 0;
double gActivated = 0, gSet = 0, gNotSet = 0, gOpenSlip = 0, gOpenHonest = 0, gBrokerClosed = 0;
double gPoint = 0, gRg = 0;
string gHTML = "", gHTMLe = "", gHTMLeq = "";
string gCSV = "", gCSVe = "", gCSVeq = "";
string gIssue = "";
string gSum = "";

// -----------------------------------------------------------------------------------------------------------------------
// Set final summary
// -----------------------------------------------------------------------------------------------------------------------

void setSummary()
{
   string vR = "";
   string vDataSep = "$";

   // calculate

   gBrokerClosed = gOpenHonest + gOpenEarn + gOpenLoss + gBiggerTP + gBiggerSL + gCutTPB + gCutSLB + gTPEqual + gSLEqual;
   gRg = ( (gOpenHonest + gOpenEarn + gBiggerTP + gCutSLB + gTPEqual + gSLEqual) / gBrokerClosed ) * 100;

   if (gRg == 100) { vR = "DEMO ?"; } 
   else if (gRg > 80) { vR = "VERY GOOD"; } 
   else if (gRg > 50) { vR = "GOOD"; }
   else if (gRg > 20) { vR = "BAD"; }
   else { vR = "VERY BAD"; }

   vR += "   ( " + DoubleToStr(gRg, 0) + "% ) ";
 
   // set summary
   
   gSum += "Final result for Broker: " + vR;
   gSum += vDataSep;   



   gSum += "Open, TP, SL slip:";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;

   if (gHasOpen) 
   {
      gSum += (string)gOpenHonest;
      gSum += vDataSep;
      gSum += "( honest broker )";
      gSum += vDataSep;
      gSum += "Open price slip and points returned at order closed by broker";
      gSum += vDataSep;

      gSum += (string)gOpenEarn;
      gSum += vDataSep;
      gSum += "( good broker )";
      gSum += vDataSep;
      gSum += "Open price slip with earn";
      gSum += vDataSep;
   }
   
   gSum += (string)gBiggerTP;
   gSum += vDataSep;
   gSum += "( good broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with bigger TakeProfit";
   gSum += vDataSep;

   gSum += (string)gCutSLB;
   gSum += vDataSep;
   gSum += "( good broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with smaller StopLoss";
   gSum += vDataSep;

   gSum += (string)gTPEqual;
   gSum += vDataSep;
   gSum += "( good broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with TakeProfit expected by trader";
   gSum += vDataSep;

   gSum += (string)gSLEqual;
   gSum += vDataSep;
   gSum += "( good broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with StopLoss expected by trader";
   gSum += vDataSep;
   
   if (gHasOpen) 
   {
      gSum += (string)gOpenLoss;
      gSum += vDataSep;
      gSum += "( bad broker )";
      gSum += vDataSep;
      gSum += "Open price slip with loss";
      gSum += vDataSep;
   }

   gSum += (string)gBiggerSL;
   gSum += vDataSep;
   gSum += "( bad broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with bigger StopLoss";
   gSum += vDataSep;

   gSum += (string)gCutTPB;
   gSum += vDataSep;
   gSum += "( bad broker )";
   gSum += vDataSep;
   gSum += "Orders closed by broker with smaller TakeProfit";
   gSum += vDataSep;
   
   gSum += (string)gBrokerClosed;
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "All orders closed by broker with StopLoss or TakeProfit";
   gSum += vDataSep;



   gSum += "Market type:";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;

   if (gHasOpen) 
   {
      gSum += (string)gOpenSlip;
      gSum += vDataSep;
      gSum += "( not very liquid market )";
      gSum += vDataSep;
      gSum += "Orders opened by broker with different open price";
      gSum += vDataSep;
   }
   
   gSum += (string)gQuickEarn;
   gSum += vDataSep;
   gSum += "( good for scalpers & robots )";
   gSum += vDataSep;
   gSum += "Quick orders with earn ( profit > 0 )";
   gSum += vDataSep;

   gSum += (string)gQuickLoss;
   gSum += vDataSep;
   gSum += "( not good for scalpers & robots )";
   gSum += vDataSep;
   gSum += "Quick orders with loss ( profit < 0 )";
   gSum += vDataSep;
   


   gSum += "Strategy type:";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;

   gSum += (string)gCutSLT;
   gSum += vDataSep;
   gSum += "( good strategy )";
   gSum += vDataSep;
   gSum += "Orders closed by trader before StopLoss activation ( cut loss )";
   gSum += vDataSep;

   gSum += (string)gCutTPT;
   gSum += vDataSep;
   gSum += "( bad strategy )";
   gSum += vDataSep;
   gSum += "Orders closed by trader before TakeProfit activation ( cut profit )";
   gSum += vDataSep;



   gSum += "All orders:";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   
   gSum += (string)gSet;
   gSum += vDataSep;
   gSum += "( secure strategy )";
   gSum += vDataSep;
   gSum += "All orders with StopLoss or TakeProfit";
   gSum += vDataSep;

   gSum += (string)gNotSet;
   gSum += vDataSep;
   gSum += "( risky strategy )";
   gSum += vDataSep;
   gSum += "All orders without StopLoss or TakeProfit";
   gSum += vDataSep;

   gSum += (string)gActivated;
   gSum += vDataSep;
   gSum += "";
   gSum += vDataSep;
   gSum += "All orders (realized except cancelled and pending )";
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
         vHTML += "<td>"+gIssue+"</td>";
      vHTML += "</tr>"+"\n";

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
         
         for (int i=1; i<ArraySize(vArr); i+=3)
         {
            vHTML += "<tr>";
               vHTML += "<td class=\"right\"><b>"+vArr[i]+"</b></td>";
               vHTML += "<td>"+vArr[i+1]+"</td>";
               vHTML += "<td>"+vArr[i+2]+"</td>";
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
   string vHTML = "", vHead = "";

   vHead += "<thead>"+"\n";
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
      vHead += "</tr>"+"\n";
   vHead += "</thead>"+"\n";

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

            vHTML += "<h2>Orders with issues closed by broker:</h2>";

            vHTML += "<table>"+"\n";
               vHTML += vHead;
               vHTML += "<tbody>"+"\n";
                  vHTML += gHTMLe;
               vHTML += "</tbody>"+"\n";
            vHTML += "</table>"+"\n";
            
            if (!gHasOpen)
            {
               vHTML += "<h2>Orders closed by broker with expected price for TP or SL:</h2>";
   
               vHTML += "<h3>This table below shows orders closed by broker with correct TP or SL price. ";
               vHTML += "If there is incorrect TP or SL size, it means there was open price slip and broker ";
               vHTML += "not gaves you slip points back at the end of order. You need to verify the ";
               vHTML += "TP and SL size on your own, if you remember how many points it should be. ";
               vHTML += "If there is not so many points this is natural thing at not very liquid market but ";
               vHTML += "if there are many orders with big difference and nothing with points back at the table above ";
               vHTML += "this may means the broker cheats you or you have totally wrong strategy ";
               vHTML += "(e.g. scalping at not very liquid market maker or index). To see more detailed report ";
               vHTML += "activate feature by adding for each order exact comment format e.g. ";
               vHTML += ":requested_open_price: to compare with OrderOpenPrice() later.</h3>";
   
               vHTML += "<table>"+"\n";
                  vHTML += vHead;
                  vHTML += "<tbody>"+"\n";
                     vHTML += gHTMLeq;
                  vHTML += "</tbody>"+"\n";
               vHTML += "</table>"+"\n";
            }

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

   vCSV += "\n" + vArr[0] + "\n\n";
   
   for (int i=1; i<ArraySize(vArr); i+=3)
   {
      vCSV += sSep + vArr[i];
      vCSV += sSep + vArr[i+1];
      vCSV += sSep + vArr[i+2];
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
         
   vCSV += "Account: " + (string)AccountNumber() + ", " + (string)AccountCompany() + "\n";
   
   vCSV += setSummaryCSV() + "\n";

   vCSV += "\n" + "Orders with issues closed by broker:" + "\n";
   vCSV += vHead;
   vCSV += gCSVe;
   vCSV += "\n";
   vCSV += "\n";
            
   if (!gHasOpen)
   {
      vCSV += "Orders closed by broker with expected price for TP or SL:" + "\n\n";

      vCSV += "This table below shows orders closed by broker with correct TP or SL price. " + "\n";
      vCSV += "If there is incorrect TP or SL size, it means there was open price slip and broker " + "\n";
      vCSV += "not gaves you slip points back at the end of order. You need to verify the " + "\n";
      vCSV += "TP and SL size on your own, if you remember how many points it should be. " + "\n";
      vCSV += "If there is not so many points this is natural thing at not very liquid market but " + "\n";
      vCSV += "if there are many orders with big difference and nothing with points back at the table above " + "\n";
      vCSV += "this may means the broker cheats you or you have totally wrong strategy " + "\n";
      vCSV += "(e.g. scalping at not very liquid market maker or index). To see more detailed report " + "\n";
      vCSV += "activate feature by adding for each order exact comment format e.g. " + "\n";
      vCSV += ":requested_open_price: to compare with OrderOpenPrice() later." + "\n";

      vCSV += "\n";
      vCSV += vHead;
      vCSV += gCSVeq;
      vCSV += "\n";
   }

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
   double vDiff = 0, vSlip = 0, vSlipVal = 0, vReq = 0;
   string k = "", kExt[];
   
   // set open slip
   if (gIsOpen)
   {
      k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt); vReq = (double)kExt[1];
      if (OrderOpenPrice() != vReq)
      {
         if (gPoint != 0)
         { 
            vSlip = MathRound((OrderOpenPrice() - vReq) / gPoint);
            vSlipVal = MathAbs(vSlip);
         }
      }
   }

   if (OrderType() == OP_BUY)
   {    
      // LOSS: bigger SL (SL slip)
      if (OrderStopLoss() > 0 && OrderClosePrice() < OrderStopLoss())
      { 
         vDiff = OrderStopLoss() - OrderClosePrice();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }
         
         if (gIsOpen)
         {
            if (vSlip > 0) {
               gIssue += "bad, loss: OPEN+" + (string)vSlipVal + " & SL+" + (string)vDiff + " "; 
               gShow = 1; gOpenLoss++;
            }
            if (vSlip < 0) {
               if (vSlipVal == vDiff) 
               {
                  gIssue += "honest broker, returned points: ";
                  gOpenHonest++;
               }
               if (vSlipVal < vDiff)
               {
                  gIssue += "bad, loss: ";
                  gOpenLoss++;
               }
               if (vSlipVal > vDiff)
               {
                  gIssue += "good, earn: ";
                  gOpenEarn++;
               }
               gIssue += "OPEN-" + (string)vSlipVal + " & SL+" + (string)vDiff + " "; 
               gShow = 1;
            }
         }
         else 
         {
            gIssue += "slip SL+" + (string)vDiff;
            gBiggerSL++; gShow = 1;
         }
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() > OrderTakeProfit())
      { 
         vDiff = OrderClosePrice() - OrderTakeProfit(); 
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         if (gIsOpen)
         {
            if (vSlip > 0) 
            { 
               if (vSlipVal == vDiff) 
               {
                  gIssue += "honest broker, returned points: ";
                  gOpenHonest++;
               }
               if (vSlipVal > vDiff)
               {
                  gIssue += "bad, loss: ";
                  gOpenLoss++;
               }
               if (vSlipVal < vDiff)
               {
                  gIssue += "good, earn: ";
                  gOpenEarn++;
               }
               gIssue += "OPEN+" + (string)vSlipVal + " & TP+" + (string)vDiff + " ";
               gShow = 1;
            }
            if (vSlip < 0) 
            { 
               gIssue += "good, earn: " + "OPEN-" + (string)vSlipVal + " & TP+" + (string)vDiff + " "; 
               gShow = 1; gOpenEarn++;
            }
         }
         else 
         {
            gIssue += "slip TP+" + (string)vDiff;
            gBiggerTP++; gShow = 1;
         }
      }
   }
   
   if (OrderType() == OP_SELL)
   {  
      // LOSS: bigger SL (SL slip)      
      if (OrderStopLoss() > 0 && OrderClosePrice() > OrderStopLoss())
      { 
         vDiff = OrderClosePrice() - OrderStopLoss();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         if (gIsOpen)
         {
            if (vSlip > 0) 
            { 
               if (vSlipVal == vDiff) 
               {
                  gIssue += "honest broker, returned points: ";
                  gOpenHonest++;
               }
               if (vSlipVal < vDiff)
               {
                  gIssue += "bad, loss: ";
                  gOpenLoss++;
               }
               if (vSlipVal > vDiff)
               {
                  gIssue += "good, earn: ";
                  gOpenEarn++;
               }
               gIssue += "OPEN+" + (string)vSlipVal + " & SL+" + (string)vDiff + " ";
               gShow = 1;
            }
            if (vSlip < 0) 
            { 
               gIssue += "bad, loss: OPEN-" + (string)vSlipVal + " & SL+" + (string)vDiff + " "; 
               gShow = 1; gOpenLoss++;
            }
         }
         else 
         {
            gIssue += "slip SL+" + (string)vDiff;
            gBiggerSL++; gShow = 1;
         }
      }
      
      // EARN: bigger TP (TP slip)
      if (OrderTakeProfit() > 0 && OrderClosePrice() < OrderTakeProfit())
      { 
         vDiff = OrderTakeProfit() - OrderClosePrice();
         if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

         if (gIsOpen)
         {
            if (vSlip > 0) 
            { 
               gIssue += "good, earn: OPEN+" + (string)vSlipVal + " & TP+" + (string)vDiff + " "; 
               gShow = 1; gOpenEarn++;
            }
            if (vSlip < 0) 
            { 
               if (vSlipVal == vDiff) 
               {
                  gIssue += "honest broker, returned points: ";
                  gOpenHonest++;
               }
               if (vSlipVal > vDiff)
               {
                  gIssue += "bad, loss: ";
                  gOpenLoss++;
               }
               if (vSlipVal < vDiff)
               {
                  gIssue += "good, earn: ";
                  gOpenEarn++;
               }
               gIssue += "OPEN-" + (string)vSlipVal + " & TP+" + (string)vDiff + " ";
               gShow = 1;
            }
         }
         else 
         {
            gIssue += "slip TP+" + (string)vDiff;
            gBiggerTP++; gShow = 1;
         }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get smaller TP or SL (closed too fast)
// -----------------------------------------------------------------------------------------------------------------------

void getSmaller() 
{
   double vDiff = 0, vSlip = 0, vSlipVal = 0, vReq = 0;
   string k = "", kExt[];
   
   // set open slip
   if (gIsOpen)
   {
      k = OrderComment(); StringSplit(k, StringGetCharacter(":",0), kExt); vReq = (double)kExt[1];
      if (OrderOpenPrice() != vReq)
      {
         if (gPoint != 0)
         { 
            vSlip = MathRound((OrderOpenPrice() - vReq) / gPoint);
            vSlipVal = MathAbs(vSlip);
         }
      }
   }

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
            vDiff = OrderClosePrice() - OrderStopLoss(); 
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            if (gIsOpen)
            {
               if (vSlip > 0) 
               { 
                  if (vSlipVal == vDiff) 
                  {
                     gIssue += "honest broker, returned points: ";
                     gOpenHonest++;
                  }
                  if (vSlipVal > vDiff)
                  {
                     gIssue += "bad, loss: ";
                     gOpenLoss++;
                  }
                  if (vSlipVal < vDiff)
                  {
                     gIssue += "good, earn: ";
                     gOpenEarn++;
                  }
                  gIssue += "OPEN+" + (string)vSlipVal + " & SL-" + (string)vDiff + " "; 
                  gShow = 1;
               }
               if (vSlip < 0) 
               { 
                  gIssue += "good, earn: OPEN-" + (string)vSlipVal + " & SL-" + (string)vDiff + " "; 
                  gShow = 1; gOpenEarn++;
               }
            }
            else 
            {
               gIssue += "slip SL-" + (string)vDiff;
               gCutSLB++; gShow = 1;
            }
         }
         
         // closed by you
         if (StringFind(k, "[sl]", 0) == -1) { gCutSLT++; }
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
            vDiff = OrderTakeProfit() - OrderClosePrice();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            if (gIsOpen)
            {
               if (vSlip > 0) 
               { 
                  gIssue += "bad, loss: OPEN+" + (string)vSlipVal + " & TP-" + (string)vDiff + " "; 
                  gShow = 1; gOpenLoss++;
               }
               if (vSlip < 0) 
               { 
                  if (vSlipVal == vDiff) 
                  {
                     gIssue += "honest broker, returned points: ";
                     gOpenHonest++;
                  }
                  if (vSlipVal < vDiff)
                  {
                     gIssue += "bad, loss: ";
                     gOpenLoss++;
                  }
                  if (vSlipVal > vDiff)
                  {
                     gIssue += "good, earn: ";
                     gOpenEarn++;
                  }
                  gIssue += "OPEN-" + (string)vSlipVal + " & TP-" + (string)vDiff + " "; 
                  gShow = 1;
               }
            }
            else 
            {
               gIssue += "slip TP-" + (string)vDiff;
               gCutTPB++; gShow = 1;
            }
         }

         // closed by you
         if (StringFind(k, "[tp]", 0) == -1) { gCutTPT++; }
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
            vDiff = OrderStopLoss() - OrderClosePrice();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }
            
            if (gIsOpen)
            {
               if (vSlip > 0) 
               { 
                  gIssue += "good, earn: OPEN+" + (string)vSlipVal + " & SL-" + (string)vDiff + " "; 
                  gShow = 1; gOpenEarn++;
               }
               if (vSlip < 0) 
               { 
                 if (vSlipVal == vDiff) 
                  {
                     gIssue += "honest broker, returned points: ";
                     gOpenHonest++;
                  }
                  if (vSlipVal > vDiff)
                  {
                     gIssue += "bad, loss: ";
                     gOpenLoss++;
                  }
                  if (vSlipVal < vDiff)
                  {
                     gIssue += "good, earn: ";
                     gOpenEarn++;
                  }
                  gIssue += "OPEN-" + (string)vSlipVal + " & SL-" + (string)vDiff + " "; 
                  gShow = 1; 
               }
            }
            else 
            {
               gIssue += "slip SL-" + (string)vDiff;
               gCutSLB++; gShow = 1;
            }
         }

         // closed by you
         if (StringFind(k, "[sl]", 0) == -1) { gCutSLT++; }
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
            vDiff = OrderClosePrice() - OrderTakeProfit();
            if (gPoint != 0) { vDiff = MathRound(vDiff / gPoint); }

            if (gIsOpen)
            {
               if (vSlip > 0) 
               { 
                 if (vSlipVal == vDiff) 
                  {
                     gIssue += "honest broker, returned points: ";
                     gOpenHonest++;
                  }
                  if (vSlipVal < vDiff)
                  {
                     gIssue += "bad, loss: ";
                     gOpenLoss++;
                  }
                  if (vSlipVal > vDiff)
                  {
                     gIssue += "good, earn: ";
                     gOpenEarn++;
                  }
                  gIssue += "OPEN+" + (string)vSlipVal + " & TP-" + (string)vDiff + " "; 
                  gShow = 1;
               }
               if (vSlip < 0) 
               { 
                  gIssue += "bad, loss: OPEN-" + (string)vSlipVal + " & TP-" + (string)vDiff + " "; 
                  gShow = 1; gOpenLoss++;
               }
            }
            else 
            {
               gIssue += "slip TP-" + (string)vDiff;
               gCutTPB++; gShow = 1;
            }
         }

         // closed by you
         if (StringFind(k, "[tp]", 0) == -1) { gCutTPT++; }
      }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Get orders closed with expected TP or SL price
// -----------------------------------------------------------------------------------------------------------------------

void getEqual() 
{
   if (OrderTakeProfit() == OrderClosePrice()) { gTPEqual++; gShow = 2; gIssue += "TP size? "; }
   if (OrderStopLoss()   == OrderClosePrice()) { gSLEqual++; gShow = 2; gIssue += "SL size? "; }
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
// Quick orders, less than 3 seconds
// -----------------------------------------------------------------------------------------------------------------------

void getQuick() 
{
   datetime vTime;
   MqlDateTime vT;
   
   vTime = OrderCloseTime() - OrderOpenTime();
   TimeToStruct(vTime, vT);
   
   if (vT.year == 1970 && vT.mon == 1 && vT.day == 1 && vT.hour == 0 && vT.min == 0) {
   
      if (vT.sec < 3 && OrderProfit() > 0) { gIssue = "QUICK "+ gIssue; gQuickEarn++; gShow = 1; }
      if (vT.sec < 3 && OrderProfit() < 0) { gIssue = "QUICK "+ gIssue; gQuickLoss++; gShow = 1; }
   }
}

// -----------------------------------------------------------------------------------------------------------------------
// Orders with open price slip. In fact you can't predict if the different open price 
// will be good or bad in the future.
// -----------------------------------------------------------------------------------------------------------------------

void getOpenSlip() 
{
   string k = "", kExt[];
   double vReq = 0, vSlip = 0;

   // exit if open feature not available in comment
   if (!gIsOpen) { return; }

   // set open slip size
   k = OrderComment();
   StringSplit(k, StringGetCharacter(":",0), kExt);
   vReq = (double)kExt[1];
   
   if (OrderOpenPrice() != vReq)
   {
      // there is open slip
      gOpenSlip++;
      
      // set open slip size
      if (gPoint != 0) { vSlip = MathRound((OrderOpenPrice() - vReq) / gPoint); }
      
      // open slip but no points back (TP equal)
      if (OrderClosePrice() == OrderTakeProfit())
      {
         if (OrderType() == OP_BUY)
         {  
            // smaller TP
            if (vSlip > 0) 
            { 
               gIssue += "bad, loss: OPEN+ => TP-" + (string)MathAbs(vSlip) + " "; 
               gOpenLoss++; gShow = 1; 
            }
            // bigger TP
            if (vSlip < 0) 
            { 
               gIssue += "good, earn: OPEN- => TP+" + (string)MathAbs(vSlip) + " "; 
               gOpenEarn++; gShow = 1; 
            }
         }
         if (OrderType() == OP_SELL)
         {
            // smaller TP
            if (vSlip < 0) 
            { 
               gIssue += "bad, loss: OPEN- => TP-" + (string)MathAbs(vSlip) + " "; 
               gOpenLoss++; gShow = 1;
            }
            // bigger TP
            if (vSlip > 0) 
            { 
               gIssue += "good, earn: OPEN+ => TP+" + (string)MathAbs(vSlip) + " "; 
               gOpenEarn++; gShow = 1;
            }
         }
      }
      
      // open slip but no points back (SL equal)
      if (OrderClosePrice() == OrderStopLoss())
      {
         if (OrderType() == OP_BUY)
         {
            // bigger SL
            if (vSlip > 0) 
            { 
               gIssue += "bad, loss: OPEN+ => SL+" + (string)MathAbs(vSlip) + " "; 
               gOpenLoss++; gShow = 1; 
            }
            // smaller SL
            if (vSlip < 0) 
            { 
               gIssue += "good, earn: OPEN- => SL-" + (string)MathAbs(vSlip) + " "; 
               gOpenEarn++; gShow = 1; 
            }
         }
         if (OrderType() == OP_SELL)
         {
            // bigger SL
            if (vSlip < 0) 
            { 
               gIssue += "bad, loss: OPEN- => SL+" + (string)MathAbs(vSlip) + " "; 
               gOpenLoss++; gShow = 1; 
            }
            // smaller SL
            if (vSlip > 0) 
            { 
               gIssue += "good, earn: OPEN+ => SL-" + (string)MathAbs(vSlip) + " "; 
               gOpenEarn++; gShow = 1; 
            }
         }
      }
   }   
}

// -----------------------------------------------------------------------------------------------------------------------
// MAIN
// -----------------------------------------------------------------------------------------------------------------------

void OnStart()
{
   int    vTotal = OrdersHistoryTotal();
   string k = "";
   
   Print("");
   Print("");
   Print(sLine);

   if (vTotal == 0) { Print("ERROR: No orders found."); return; }

   for (int i=0; i<vTotal; i++) 
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) { continue; }
     
      // reset values for each order
      gShow = 0; gIssue = ""; gIsOpen = false;

      // for old markets, need to open chart to load data to get it worked
      gPoint = MarketInfo(OrderSymbol(), MODE_POINT);
      
      // check if there is open feature active in comment
      k = OrderComment(); if (StringFind(k, ":", 0) != -1) { gIsOpen = true; gHasOpen = true; }
      
      getBigger();         // bigger TP or SL
      getSmaller();        // smaller TP or SL

      if (OrderType() == OP_BUY || OrderType() == OP_SELL)
      {
         getWithSet();     // with set TP or SL
         getWithNotSet();  // with not set TP or SL
         getQuick();       // quick orders
         getEqual();       // expected TP or SL price
         getOpenSlip();    // open slip with expected TP or SL price
         
         gActivated++;     // all olders but only activated
      }
      if (gShow == 1 || gShow == 2) { setEntry(); }  // issues
   }
   
   setSummary();  // calculate final result
   
   if (sHTML) { setHTMLFile(); }  // save HTML output to file 
   if (sCSV) { setCSVFile(); }    // save CSV output to file

   Print(sLine);
}
