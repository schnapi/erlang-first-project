function alertj(obj) {
  alert(JSON.stringify(obj))
}
new Vue({
  el: '#question',
  data: {
    questionnaireId: {{ questionnaireId }},
    numOfQuestions: 0,
    question: "",
    pid: 0,
    processingSpeed: 0,
    brainCapacity: 0,
    brainWeight: 0,
    answerId: 0,
    scoring : {{scoring}},
    max_score : {{max_score}},
    image: "test.jpg"
  },
  mounted: function() {
      var userdata = JSON.stringify({
        "child": this.questionnaireId
      }); self=this
      $.postJSON("/api/questionnaire", userdata, function(data) {
        if(data.error) alert(data.error);
        else {
          self.pid=data.pid
          self.numOfQuestions=data.numOfQuestions
          self.nextQuestion()
        }
      })
  },
  methods: {
    nextQuestion: function() {
      var data = JSON.stringify({
        "question": "next",
        "questionnaireId": this.questionnaireId,
        "questionId": this.question.id,
        "answerId": this.question.answers_type=="motivation"?-1:this.answerId,
        "pid" : this.pid,
        "scoring" : this.scoring
      });
      self=this
      $.postJSON("/api/questionnaire", data, function(data) {
        if(data.error) alert(data.error);
        else {
          if(data.question=="") {
            alert("Vprašalnik končan!")
            window.history.replaceState(null, "test", location.protocol + '//' + location.host + "/")
            window.location.href = "/questionnaires"
          }
          else {
            try {
              if(data.question.answers != "undefined") {
                data.question.answers = JSON.parse(data.question.answers)
                self.answerId = 0
              }
              else {
                data.question["answers"] = []
                self.answerId = -1 // if we send 0 to server, server would return same question, if -1 server returns nextdefault question
              }
              self.question=data.question
              self.processingSpeed=data.processingSpeed
              self.brainCapacity=data.brainCapacity
              self.brainWeight=data.brainWeight
            } catch(ex) {
              alert("Napaka: "+data.question.answers)
            }
          }
        }
      })
    }
  }
})
