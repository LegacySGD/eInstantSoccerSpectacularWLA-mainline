<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario             = getScenario(jsonContext);
						var scenarioMainGame     = getMainGameData(scenario);
						var scenarioBonus1       = getBonus1Data(scenario);
						var scenarioBonus2       = getBonus2Data(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames           = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const lineMultiIndexes = [0,0,1,2,2];
						const prizesMainGame   = 'abcdefghijkl';
						const winTrigger       = 3;

						var arrMainGameData   = [];
						var arrMainGameLines  = scenarioMainGame[0].split(',');
						var arrMainGameMultis = scenarioMainGame[1].split(',');

						function getParsedMainGame(A_strLineData, A_strMultiData)
						{
							var objLine   = {arrPrizes: [], strWinPrize: '', iMulti: 0};
							var prizeQty  = prizesMainGame.split('').map(function(item) {return 0;} );
							var symbChar  = '';
							var symbIndex = -1;

							objLine.arrPrizes = A_strLineData.split('');
							objLine.iMulti    = parseInt(A_strMultiData, 10);

							for (var lineSymbIndex = 0; lineSymbIndex < A_strLineData.length; lineSymbIndex++)
							{
								symbChar  = A_strLineData[lineSymbIndex];
								symbIndex = prizesMainGame.indexOf(symbChar);
								
								prizeQty[symbIndex]++;

								if (prizeQty[symbIndex] == winTrigger)
								{
									objLine.strWinPrize = symbChar;
								}
							}

							return objLine;
						}

						for (var lineIndex = 0; lineIndex < arrMainGameLines.length; lineIndex++)
						{
							arrMainGameData.push(getParsedMainGame(arrMainGameLines[lineIndex], arrMainGameMultis[lineMultiIndexes[lineIndex]]));
						}

						/////////////////////////
						// Currency formatting //
						/////////////////////////

						var bCurrSymbAtFront = false;
						var strCurrSymb      = '';
						var strDecSymb       = '';
						var strThouSymb      = '';

						function getCurrencyInfoFromTopPrize()
						{
							var topPrize               = convertedPrizeValues[0];
							var strPrizeAsDigits       = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
							var iPosFirstDigit         = topPrize.indexOf(strPrizeAsDigits[0]);
							var iPosLastDigit          = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
							bCurrSymbAtFront           = (iPosFirstDigit != 0);
							strCurrSymb 	           = (bCurrSymbAtFront) ? topPrize.substr(0,iPosFirstDigit) : topPrize.substr(iPosLastDigit+1);
							var strPrizeNoCurrency     = topPrize.replace(new RegExp('[' + strCurrSymb + ']', 'g'), '');
							var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
							strDecSymb                 = strPrizeNoDigitsOrCurr.substr(-1);
							strThouSymb                = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
						}

						function getPrizeInCents(AA_strPrize)
						{
							return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
						}

						function getCentsInCurr(AA_iPrize)
						{
							var strValue = AA_iPrize.toString();

							strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
							strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
							strValue = (strValue.length > 6) ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
							strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

							return strValue;
						}

						getCurrencyInfoFromTopPrize();

						///////////////
						// UI Config //
						///////////////

						const boxHeight     = 25;
						const boxWidthSymb  = 50;
						const boxWidthPrize = 120;
						const boxMargin     = 1;
						const boxTextY      = 15;
						
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourCyan    = '#ccffff';
						const colourFuschia = '#ff99cc';
						const colourGold    = '#ffdd77';
						const colourGreen   = '#99ff99';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourNavy    = '#0000ff';						
						const colourOrange  = '#ffaa55';
						const colourPink    = '#ffcccc';
						const colourPurple  = '#cc99ff';
						const colourRed     = '#ff9999';						
						const colourScarlet = '#ff0000';
						const colourWhite   = '#ffffff';
						const colourYellow  = '#ffff00';

						const symbBonus1   = '1';
						const symbBonus2   = '2';
						const symbSpecials =  symbBonus1 + symbBonus2;

						const mgPrizeColours     = [colourRed, colourOrange, colourGold, colourLemon, colourLime, colourGreen, colourCyan, colourBlue, colourLilac, colourPurple, colourFuschia, colourPink];
						const specialBoxColours  = [colourScarlet, colourNavy];
						const specialTextColours = [colourYellow, colourYellow];

						var boxColourStr  = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var textColourStr = '';

						var r = [];

						function showBox(A_strCanvasId, A_strCanvasElement, A_iBoxWidth, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = A_iBoxWidth + 2 * boxMargin;
							var canvasHeight = boxHeight + 2 * boxMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (boxMargin + 0.5).toString() + ', ' + (boxMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + boxHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (boxMargin + 1.5).toString() + ', ' + (boxMargin + 1.5).toString() + ', ' + (A_iBoxWidth - 2).toString() + ', ' + (boxHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + 1).toString() + ', ' + boxTextY.toString() + ');');
							r.push('</script>');
						}

						///////////////////////
						// Prize Symbols Key //
						///////////////////////

						var prizeIndex  = -1;
						var symbPrize   = '';
						var symbDesc    = '';
						var symbSpecial = '';

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td colspan="4" style="padding-bottom:10px">' + getTranslationByName("titlePrizeSymbolsKey", translations) + '</td>');
						r.push('</tr>');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td style="padding-left:10px; padding-right:30px">' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td style="padding-left:10px">' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var rowIndex = 0; rowIndex < prizesMainGame.length / 2; rowIndex++)
						{
							r.push('<tr class="tablebody">');

							for (var colIndex = 0; colIndex < 2; colIndex++)
							{
								prizeIndex   = colIndex * prizesMainGame.length / 2 + rowIndex;
								symbPrize    = prizesMainGame[prizeIndex];
								canvasIdStr  = 'cvsKeySymb' + symbPrize;
								elementStr   = 'eleKeySymb' + symbPrize;
								boxColourStr = mgPrizeColours[prizeIndex];
								symbDesc     = 'symbm' + symbPrize;

								r.push('<td align="center">');

								showBox(canvasIdStr, elementStr, boxWidthSymb, boxColourStr, colourBlack, symbPrize.toUpperCase());

								r.push('</td>');
								r.push('<td style="padding-left:10px">' + getTranslationByName(symbDesc, translations) + '</td>');
							}

							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						/////////////////////////
						// Special Symbols Key //
						/////////////////////////

						r.push('<div style="float:left">');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<td colspan="2" style="padding-bottom:10px">' + getTranslationByName("titleSpecialSymbolsKey", translations) + '</td>');
						r.push('</tr>');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td style="padding-left:10px">' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var specialIndex = 0; specialIndex < symbSpecials.length; specialIndex++)
						{
							symbSpecial   = symbSpecials[specialIndex];
							canvasIdStr   = 'cvsKeySymb' + symbSpecial;
							elementStr    = 'eleKeySymb' + symbSpecial;
							boxColourStr  = specialBoxColours[specialIndex];
							textColourStr = specialTextColours[specialIndex];
							symbDesc      = 'symbm' + symbSpecial;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showBox(canvasIdStr, elementStr, boxWidthSymb, boxColourStr, textColourStr, symbSpecial);

							r.push('</td>');
							r.push('<td style="padding-left:10px">' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						const bonusTrigger = 3;

						var zoneChange    = false;
						var zonePad       = 0;
						var zoneStr       = '';
						var lineStr       = '';
						var multiStr      = '';
						var isSpecial     = false;
						var prizeText     = '';
						var prizeVal      = '';
						var winText       = '';
						var bonusQtys     = symbSpecials.split('').map(function(item) {return 0;} );
						var lineBonusQtys = [];
						var countText     = '';
						var collectedText = '';
						var bonusGame     = '';
						var triggerText   = '';
						var zoneFirst     = true;
						var isWinner      = false;

						r.push('<div style="clear:both">');
						r.push('<p><br>' + getTranslationByName("mainGame", translations).toUpperCase() + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						for (var lineIndex = 0; lineIndex < arrMainGameData.length; lineIndex++)
						{
							lineBonusQtys = symbSpecials.split('').map(function(item) {return 0;} );
							zoneChange    = (lineIndex == 0 || lineMultiIndexes[lineIndex] != lineMultiIndexes[lineIndex-1]);
							zonePad       = (lineIndex == 0) ? 0 : ((zoneChange) ? 50 : 15);
							zoneFirst     = true;

							r.push('<tr class="tablebody">');

							//////////
							// Zone //
							//////////

							zoneStr = (zoneChange) ? getTranslationByName("mgZone", translations).toUpperCase() + ' ' + (lineMultiIndexes[lineIndex] + 1).toString() : '';

							r.push('<td style="padding-top:' + zonePad.toString() + 'px">' + zoneStr + '</td>'); 

							//////////
							// Line //
							//////////

							lineStr = getTranslationByName("mgLine", translations) + ' ' + (lineIndex + 1).toString();

							r.push('<td style="padding-left:30px; padding-top:' + zonePad.toString() + 'px">' + lineStr + '</td>'); 

							/////////////
							// Symbols //
							/////////////

							r.push('<td style="padding-left:20px; padding-top:' + zonePad.toString() + 'px">');

							for (var charIndex = 0; charIndex < arrMainGameData[lineIndex].arrPrizes.length; charIndex++)
							{
								canvasIdStr   = 'cvsLineSymb' + lineIndex.toString() + '_' + charIndex.toString();
								elementStr    = 'eleLineSymb' + lineIndex.toString() + '_' + charIndex.toString();
								symbPrize     = arrMainGameData[lineIndex].arrPrizes[charIndex];
								isSpecial     = (symbSpecials.indexOf(symbPrize) != -1);
								prizeIndex    = (isSpecial) ? symbSpecials.indexOf(symbPrize) : prizesMainGame.indexOf(symbPrize);								
								boxColourStr  = (isSpecial) ? specialBoxColours[prizeIndex] : mgPrizeColours[prizeIndex];
								textColourStr = (isSpecial) ? specialTextColours[prizeIndex] : colourBlack;
								symbDesc      = (isSpecial) ? symbPrize : symbPrize.toUpperCase();

								if (isSpecial)
								{
									bonusQtys[prizeIndex]++;
									lineBonusQtys[prizeIndex]++;
								}

								showBox(canvasIdStr, elementStr, boxWidthSymb, boxColourStr, textColourStr, symbDesc);
							}

							r.push('</td>');

							///////////
							// Multi //
							///////////

							multiStr = (zoneChange) ? getTranslationByName("mgZone", translations) + ' ' + (lineMultiIndexes[lineIndex] + 1).toString() + ' ' + getTranslationByName("mgZoneMulti", translations) +
													': x' + arrMainGameData[lineIndex].iMulti.toString() : '';

							r.push('<td style="padding-left:30px; padding-top:' + zonePad.toString() + 'px">' + multiStr + '</td>');

							//////////
							// Wins //
							//////////

							if (arrMainGameData[lineIndex].strWinPrize != '')
							{
								canvasIdStr  = 'cvsLineWin' + lineIndex.toString();
								elementStr   = 'eleLineWin' + lineIndex.toString();
								symbPrize    = arrMainGameData[lineIndex].strWinPrize;
								prizeIndex   = prizesMainGame.indexOf(symbPrize);
								boxColourStr = mgPrizeColours[prizeIndex];
								prizeText    = convertedPrizeValues[getPrizeNameIndex(prizeNames, 'm' + symbPrize)];
								prizeVal     = getCentsInCurr(getPrizeInCents(prizeText) * arrMainGameData[lineIndex].iMulti);
								winText      = prizeText + ' x ' + arrMainGameData[lineIndex].iMulti.toString() + ' = ' + prizeVal;

								r.push('<td style="padding-left:20px; padding-top:' + zonePad.toString() + 'px">');
								r.push('<table border="0" cellpadding="0" cellspacing="0" class="gameDetailsTable">');
								r.push('<tr class="tablebody">');
								r.push('<td>' + getTranslationByName("win", translations) + ':</td>');
								r.push('<td align="center" style="padding-left:10px; padding-right:10px">');

								showBox(canvasIdStr, elementStr, boxWidthSymb, boxColourStr, colourBlack, symbPrize.toUpperCase());

								r.push('</td>');
								r.push('<td>' + winText + '</td>');
								r.push('</tr>');
								r.push('</table>');
								r.push('</td>');
								r.push('</tr>');

								zoneFirst = false;
							}

							if (lineBonusQtys.reduce(function(total,num) {return total + num;} ) > 0)
							{
								for (var symbIndex = 0; symbIndex < symbSpecials.length; symbIndex++)
								{
									if (zoneFirst)
									{
										r.push('<td style="padding-left:20px; padding-top:' + zonePad.toString() + 'px">');

										zoneFirst = false;
									}
									else
									{
										r.push('<tr class="tablebody"><td></td><td></td><td></td><td></td><td style="padding-left:20px">');
									}

									if (lineBonusQtys[symbIndex] > 0)
									{
										countText     = lineBonusQtys[symbIndex].toString() + ' x';
										canvasIdStr   = 'cvsLineBonus' + lineIndex.toString() + '_' + symbIndex.toString();
										elementStr    = 'eleLineBonus' + lineIndex.toString() + '_' + symbIndex.toString();
										boxColourStr  = specialBoxColours[symbIndex];
										textColourStr = specialTextColours[symbIndex];
										symbSpecial   = symbSpecials[symbIndex];
										collectedText = getTranslationByName("collected", translations) + ' ' + bonusQtys[symbIndex] + ' ' + getTranslationByName("collectedOf", translations) + ' ' + bonusTrigger.toString();
										bonusGame     = 'bonusGame' + (symbIndex + 1).toString();
										triggerText   = (bonusQtys[symbIndex] == bonusTrigger) ? ' : ' + getTranslationByName(bonusGame, translations) + ' ' + getTranslationByName("bonusTriggered", translations) : ''; 

										r.push('<table border="0" cellpadding="0" cellspacing="0" class="gameDetailsTable">');
										r.push('<tr class="tablebody">');
										r.push('<td align="right">' + countText + '</td>');
										r.push('<td align="center" style="padding-left:10px; padding-right:10px">');

										showBox(canvasIdStr, elementStr, boxWidthSymb, boxColourStr, textColourStr, symbSpecial);
										
										r.push('</td>');
										r.push('<td>' + collectedText + triggerText + '</td>');
										r.push('</tr>');
										r.push('</table>');
									}
								}

								r.push('</td>');
								r.push('</tr>');
							}
						}

						r.push('</table>');
						r.push('</div>');

						/////////////
						// Bonus 1 //
						/////////////

						if (bonusQtys[symbSpecials.indexOf(symbBonus1)] == bonusTrigger)
						{
							const bonus1WinSymbs = 'abcdefghijklmno';

							prizeVal = 0;

							r.push('<div style="clear:both">');
							r.push('<p><br>' + getTranslationByName("bonusGame1", translations).toUpperCase() + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (turnIndex = 0; turnIndex < scenarioBonus1.length; turnIndex++)
							{
								lineStr      = getTranslationByName("bgTurn", translations) + ' ' + (turnIndex + 1).toString();
								canvasIdStr  = 'cvsB1Turn' + turnIndex.toString();
								elementStr   = 'eleB1Turn' + turnIndex.toString();
								symbPrize    = scenarioBonus1[turnIndex];
								isWinner     = (bonus1WinSymbs.indexOf(symbPrize) != -1);
								boxColourStr = (isWinner) ? colourLime : colourWhite;
								prizeText    = convertedPrizeValues[getPrizeNameIndex(prizeNames, 'b' + symbPrize.toLowerCase())];
								prizeVal    += (isWinner) ? getPrizeInCents(prizeText) : 0;

								r.push('<tr class="tablebody">');
								r.push('<td>' + lineStr + '</td>');
								r.push('<td align="center" style="padding-left:20px">');

								showBox(canvasIdStr, elementStr, boxWidthPrize, boxColourStr, colourBlack, prizeText);

								r.push('</td>');
								r.push('</tr>');
							}

							r.push('</table>');

							r.push('<br>' + getTranslationByName("bonusGame1", translations) + ' ' + getTranslationByName("win", translations) + ': ' + getCentsInCurr(prizeVal));

							r.push('</div>');
						}

						/////////////
						// Bonus 2 //
						/////////////

						if (bonusQtys[symbSpecials.indexOf(symbBonus2)] == bonusTrigger)
						{
							const bonus2WinSymbs  = 'abcdefghijklmno';
							const prizesAvailable = 8;

							prizeVal = 0;

							r.push('<div style="clear:both">');
							r.push('<p><br>' + getTranslationByName("bonusGame2", translations).toUpperCase() + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (var turnIndex = 0; turnIndex < scenarioBonus2[1].length; turnIndex++)
							{
								lineStr = getTranslationByName("bgTurn", translations) + ' ' + (turnIndex + 1).toString();

								r.push('<tr class="tablebody">');
								r.push('<td>' + lineStr + '</td>');
								r.push('<td style="padding-left:20px; padding-right:30px">');

								for (var prizeIndex = 0; prizeIndex < prizesAvailable; prizeIndex++)
								{
									canvasIdStr  = 'cvsB2Prize' + turnIndex.toString() + '_' + prizeIndex.toString();
									elementStr   = 'eleB2Prize' + turnIndex.toString() + '_' + prizeIndex.toString();
									isWinner     = (scenarioBonus2[1][turnIndex] == (prizeIndex + 1).toString());
									boxColourStr = (isWinner) ? colourLime : colourWhite;
									symbPrize    = scenarioBonus2[0][prizeIndex];
									prizeText    = convertedPrizeValues[getPrizeNameIndex(prizeNames, 'c' + symbPrize)];
									prizeVal    += (isWinner) ? getPrizeInCents(prizeText) : 0;

									showBox(canvasIdStr, elementStr, boxWidthPrize, boxColourStr, colourBlack, prizeText);
								}

								if (scenarioBonus2[1][turnIndex] != '0')
								{
									prizeIndex = parseInt(scenarioBonus2[1][turnIndex], 10) - 1;

									scenarioBonus2[0] = scenarioBonus2[0].slice(0,prizeIndex) + scenarioBonus2[0][prizesAvailable] + scenarioBonus2[0].slice(prizeIndex+1,prizesAvailable) + scenarioBonus2[0].slice(prizesAvailable+1);
								}

								r.push('</td>');
								r.push('</tr>');
							}

							r.push('</table>');

							r.push('<br>' + getTranslationByName("bonusGame2", translations) + ' ' + getTranslationByName("win", translations) + ': ' + getCentsInCurr(prizeVal));

							r.push('</div>');
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if (debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for (var idx = 0; idx < debugFeed.length; idx++)
 							{
								if (debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");
						
						for (var i = 0; i < pricePoints.length; ++i)
						{
							if (wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						
						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getMainGameData(scenario)
					{
						return scenario.split('|')[0].split(':');
					}

					function getBonus1Data(scenario)
					{
						return scenario.split('|')[1];
					}

					function getBonus2Data(scenario)
					{
						return scenario.split('|')[2].split(',');
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; i++)
						{
							if (prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////

					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if (childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
