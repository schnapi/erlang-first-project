
UtilitySearchParams= undefined
function getUrlParams() {
  let url = new URL(window.location.href);
  UtilitySearchParams = new URLSearchParams(url.search);
}
getUrlParams()

function getUrlParam(val) {
  return UtilitySearchParams.get(val);
}
