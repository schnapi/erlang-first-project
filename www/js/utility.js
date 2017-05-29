
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

jQuery["postJSON"] = function( url, data, callback ) {
    // shift arguments if data argument was omitted
    if ( jQuery.isFunction( data ) ) {
        callback = data;
        data = undefined;
    }

    return jQuery.ajax({
        url: url,
        type: "POST",
        contentType:"application/json; charset=UTF-8",
        dataType: "json",
        data: data,
        success: callback
    });
};

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

function addThought() {
  var th = $("textarea#thought").val();

  $.post("/api/thoughts", JSON.stringify({"thought":th}), function(data) {
    if(data) {
      alert("Uspešno vnešena misel.");
      $("#thoughtModal").modal("hide");
    }
  })
}
