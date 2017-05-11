function logout() {
  $.post("api/logout", {}, function(data) {
    window.location = "/";
  })
}
