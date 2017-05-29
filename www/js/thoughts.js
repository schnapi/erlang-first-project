new Vue({
  el: '#thoughts-model',
    data: {
      thought: '',
      thoughts: []
    },
    mounted: function() {
      this.fetchData();
    },
    methods: {
      fetchData() {
        var self = this
        $.get("/api/thoughts", function(data) {
          self.thoughts = data;
        })
      },
      saveThought: function() {
        var data = JSON.stringify({
          "thought": this.$data.thought
        });
        self=this
        if(this.$data.thought != "") {
          $.post("/api/thoughts", data, function(data) {
            if(data) {
              self.fetchData();
              self.$data.thought = '';
              alert("Uspešno vnešena misel.");
            }
          })
        }
        else {
          alert("Nobena misel do zdaj še ni bila prazna.");
        }
      }
    }
});
