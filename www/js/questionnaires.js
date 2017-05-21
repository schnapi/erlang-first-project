new Vue({
  el: '#questionnaires',
  data: {
    questionnaires: [],
    questionnaireInProgressId: -1
  },
  mounted: function() {
    var userdata = JSON.stringify({
      "get": "all",
    });
    var self=this
    $.post("/api/view_questionnaires", userdata, function(data) {
      if (data.error) { alert(data.error); alert("Napaka pri branju podatkov!");
      } else {
        // alertj(data)
        self.questionnaires= data.questionnaires
        self.questionnaireInProgressId = data.questionnaireInProgressId
      }
    })
  },
  methods: {
    vuePOST: function(url, params) {
      POST(url, params)
    }
  }
})
