
  Vue.component('modal', {
    template: '#modal-template'
  })

  new Vue({
    el: '#avatars',
    data: {
      filesManager: [],
      showModalGallery: false,
      selectedImage: "",
      avatar: "",
      folder: "",
      avatarName: ""
    },
    mounted: function() {
      var data = JSON.stringify({
        "get": "user"
      });
      var self=this
      $.post("/api/registration", data, function(data) {
        if (data.error) {
          alert(data.error);alert("Napaka pri branju podatkov!");}
        else {
          self.avatar = data.avatar
          self.folder = data.avatarFolder
          self.avatarName = data.avatarName
        }
      })
    },
    methods: {
      showModalGalleryF: function() {
        this.showModalGallery=true;
        var data = JSON.stringify({
          "getAllFiles": "path_avatars"
        });
        var self=this
        $.post("/api/edit_files", data, function(data) {
          if (data.error) {
            alert(data.error);alert("Napaka pri branju podatkov!");}
          else {
            self.filesManager = data
          }
        })
      },
      saveUser: function() {
        var data = JSON.stringify({
          update: {avatar:this.avatar, avatarName:this.avatarName}
        });
        var self=this
        $.post("/api/registration", data, function(data) {
          if (data.error) {
            alert(data.error);alert("Napaka pri branju podatkov!");}
          else {
            alert("Uspešno posodobljeni podatki!")
          }
        })
      },
      close: function () {
        this.showModalGallery = false
      },
      selectImage(index) {
        this.avatar = this.filesManager.files[index]
        this.folder = this.filesManager.folder
        this.close()
      }
    }
  })
