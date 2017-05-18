function alertj(obj) {
  alert(JSON.stringify(obj))
}
new Vue({
  el: '#questionnaires',
  data: {
    questionnaires: []
  },
  mounted: function() {
    var userdata = JSON.stringify({
      "get": "all",
    });
    var self=this
    $.post("/api/view_questionnaires", userdata, function(data) {
      if (data) {
        self.questionnaires= data
      } else {
        alert(data.error);
        alert("Napaka pri branju podatkov!");
      }
    })
  },
  methods: {
    vuePOST: function(url, params) {
      POST(url, params)
    }
  }
})
