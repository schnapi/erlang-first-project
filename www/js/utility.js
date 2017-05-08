
UtilitySearchParams= undefined
function getUrlParams() {
  let url = new URL(window.location.href);
  UtilitySearchParams = new URLSearchParams(url.search);
}
getUrlParams()

function getUrlParam(val) {
  return UtilitySearchParams.get(val);
}

function drawCanvasBackground() {
  var yPosMax = 175;
  var yPosMin = 125;
  var yPosStart = 150;
  var xPosStart = -50;
  var yPosChangeMultiplier = 60;
  var xPosChangeMin = 125;
  var xPosChangeMultiplier = 25;
  var yControlMultiplier = 20;
  var yControlMin = 40;

  /*
   * End Config Vars
   */

  canvas = document.getElementById('canvasBackground');
  context = canvas.getContext('2d');
  context.fillStyle = '#ecf0f1';
  var xPos = xPosStart;
  var yPos = yPosStart;
  context.beginPath();
  context.moveTo(xPos, yPos);
  while (xPos < canvas.width) {
    lastX = xPos;
  	xPos += Math.floor(Math.random() * xPosChangeMultiplier + xPosChangeMin);
  	yPos += Math.floor(Math.random() * yPosChangeMultiplier - yPosChangeMultiplier/2);
  	while (yPos < yPosMin) {
  		yPos += Math.floor(Math.random() * yPosChangeMultiplier/2);
  	}
  	while (yPos > yPosMax) {
  		yPos -= Math.floor(Math.random() * yPosChangeMultiplier/2);
  	}
    controlX = (lastX + xPos)/2;
    controlY = yPos-Math.floor(Math.random() * yControlMultiplier + yControlMin);
  	context.quadraticCurveTo(controlX,controlY,xPos,yPos);
  }
  context.lineTo(canvas.width,yPos);
  context.lineTo(canvas.width,canvas.height);
  context.lineTo(0,canvas.height);
  context.fill();
}
