new Vue({
    el: '#login',
      data: {
        email: '',
        password: ''
      },
      methods: {
        login: function(e) {
          var userdata = JSON.stringify({
            "email": this.$data.email,
            "password": this.$data.password
          });
          self=this
          if(this.$data.email != "" && this.$data.password != "") {
            $.post("/api/login", userdata, function(data) {
              if(data.error)
                alert(data.error);
              else {
                window.location = "/";
              }
            })
          }
          else {
            alert("Email in geslo sta obvezni polji.");
          }
        }
      }
  });
