
Array.prototype.spliceArray = function(index, n, array) {
  return Array.prototype.splice.apply(this, [index, n].concat(array));
}

Array.prototype.clone = function() {
  return JSON.parse(JSON.stringify(this))
}
Array.prototype.peekBack = function() {
  return this[this.length-1]
}

function alertj(obj) {
  alert(JSON.stringify(obj))
}

function clone(obj) {
  return JSON.parse(JSON.stringify(obj))
}

UtilitySearchParams= undefined
function getUrlParams() {
  let url = new URL(window.location.href);
  UtilitySearchParams = new URLSearchParams(url.search);
}
getUrlParams()

function getUrlParam(val) {
  return UtilitySearchParams.get(val);
}

function POST(url, params) {
    var form = document.createElement('form');
    form.action = url;
    form.method = 'POST';
    form.enctype='application/x-www-form-urlencoded'
    for (var i in params) {
        if (params.hasOwnProperty(i)) {
            var input = document.createElement('input');
            input.type = 'hidden';
            input.name = i;
            input.value = params[i];
            form.appendChild(input);
        }
    }
    document.body.appendChild(form);
    form.submit();
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
