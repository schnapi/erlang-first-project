// $(document).ready(function() {
// })
function removeQuestionnaire(cur) {
  var userdata = JSON.stringify({
    "remove": $(cur).closest("tr").find(".id").val(),
  });
  $.post("/api/edit_questionnaire", userdata, function(data) {
    if(data.error)
      alert(data.error);
    else {
      alert("Ustrezno vnešeni podatki, success");
      $(cur).closest("tr").remove();
    }
  })

}
function newQuestionnaire() {
  location.href = '/edit_questionnaire';
}
