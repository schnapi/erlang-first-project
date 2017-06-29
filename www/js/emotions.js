new Vue({
    el: '#tab-list',
    data: {
      currentBrainInstruction: '',
      tabs:
      {
        emotionReview: {
          id : 0,
          isActive: true
        },
        emotionIdentification: {
          id : 1,
          isActive: false
        }
      },
      activeTab: {},
      possibleOptions: [],
      emotion_type: '',
      emotion_intensity: '',
      complete_emotion: '',
      showCircle: false,
      showSaveButton: false,
      emotionReviewType: ''
    },
    mounted: function () {
      $('#welcomeTitleEmotions').modal('show');
      this.activeTab = this.tabs.emotionReview;
      this.startWithEmotionReview();
    },

    methods: {
      setActive: function (tab) {
        var self = this;
        tab.isActive = true;
        this.activeTab = tab;
        if (self.tabs.emotionReview.id !== self.activeTab.id) { self.tabs.emotionReview.isActive = false;}
        if (self.tabs.emotionIdentification.id !== self.activeTab.id) { self.tabs.emotionIdentification.isActive = false;}
        // identifikacija čustev
        if(this.activeTab.id == this.tabs.emotionIdentification.id) {
          self.startWithEmotionIdentification();
        }
        else if(this.activeTab.id == this.tabs.emotionReview.id) {
          self.startWithEmotionReview();
        }
      },
      startWithEmotionIdentification: function() {
        this.showCircle = false;
        this.showSaveButton = false;
        this.currentBrainInstruction = 'Pred tabo sta dva gumba, ki ti bosta v pomoč pri identifikaciji počutja. Za začetek označi ali je tvoje trenutno doživljanje bolj prijetno ali bolj neprijetno.';
        this.possibleOptions = [
          {
            text:"Prijetno",
            value:"positive",
            func:this.secondPhase
          },
          {
            text:"Neprijetno",
            value:"negative",
            func: this.secondPhase
          }
        ];
      },
      secondPhase: function(value) {
        this.showCircle = false;
        this.emotion_type = value;
        this.currentBrainInstruction = "S klikom označi ali gre za močno, intenzivno čustvo ali šibko, manj intenzivno."
        this.possibleOptions = [
          {
            text:"Močno",
            value:"strong",
            func:this.thirdPhase
          },
          {
            text:"Šibko",
            value:"weak",
            func: this.thirdPhase
          }
        ];
      },
      thirdPhase: function(value) {
        this.emotion_intensity = value;
        this.complete_emotion = this.emotion_type + this.emotion_intensity;
        this.currentBrainInstruction = "Pred tabo je krog, ki ponazarja različna počutja. Tvoje trenutno počutje je poudarjeno s temnejšo modro barvo. \nOdločitev lahko spremeniš s klikom na drug del kroga."
        this.possibleOptions = [];
        this.showSaveButton = true;
        this.showCircle = true;
      },
      switchEmotion: function(type, intensity) {
        this.emotion_type = type;
        this.emotion_intensity = intensity;
        this.complete_emotion = type + intensity;
        this.showSaveButton = true;
      },
      saveEmotion: function() {
        var emotiondata = JSON.stringify({
          "emotion_type": this.$data.emotion_type,
          "emotion_intensity": this.$data.emotion_intensity
        });
        $.post("/api/emotions", emotiondata, function(data) {
          if(data.error)
            alert(data.error);
          else {
            alert("Tvoje počutje je uspešno shranjeno. Preveri izrisan graf");
          }
        })
      },
      startWithEmotionReview: function() {
        this.emotionReviewType = "";
        this.currentBrainInstruction = "Tukaj lahko pregledaš statistiko svojega počutja izrisano v grafu. Izbiraš lahko med različnimi obdobji. ";
      },
      makeGraph: function(chartData) {
        var t = [];
        for(var i = 0; i < chartData.length; i++) {
          var tmp = {};
          tmp["y"] = chartData[i]["dateCreatedStr"];
          // gre za a
          if(chartData[i]["emotion_type"] == "positive") {
            // gre za 1
            if(chartData[i]["emotion_intensity"] == "strong") {
              tmp["a"] = 1;
            }
            else {
              tmp["a"] = 0;
            }
          }
          // gre za b
          else {
            if(chartData[i]["emotion_intensity"] == "strong") {
              tmp["b"] = 1;
            }
            else {
              tmp["b"] = 0;
            }
          }
          t.push(tmp);
        }
        var chart = Morris.Line({
          element: 'morris-area-chart',
          data: t,
          xkey: 'y',
          ymin: 0,
          ymax: 1,
          parseTime: false,
          ykeys: ['a', 'b'],
          yLabelFormat: function (y) {
            if(y == 0) {
              return 'šibko';
            }
            else if (y == 1) {
              return 'močno';
            }
            else {
              return 'neopredeljeno';
            }
          },
          labels: ['pozitivno', 'negativno']
        });
        chart.options.labels.forEach(function(label, i){
            var legendItem = $('<span></span>').text(label).css('color', chart.options.lineColors[i])
            $('#legend').append(legendItem)
        })
      },
      onChange: function() {
        if(this.emotionReviewType == 'weekly') {
            this.currentBrainInstruction = "Raziskave kažejo, da smo ljudje v najslabšem razpoloženju v začetku tedna (v nedeljo in skozi ves ponedeljek). Raven pozitivnih emocij se nato zviša v torek, zopet nekoliko upade v sredo, ter se izjemno izboljša ob koncu tedna. Najboljše razpoloženje, z največ pozitivnimi in najmanj negativnimi čustvi velja za soboto.";
        }
        else {
          this.currentBrainInstruction = "Tukaj lahko vidiš tudi kako se je počutje spreminalo skozi trenuten mesec.";
        }
        $("#morris-area-chart").html("");
        $('#legend').html("");
        var self = this;
        $.get("/api/emotions/user/" + this.emotionReviewType, function(data) {
          if(data.error)
            alert(data.error);
          else {
            if(data.length > 0) {
              self.makeGraph(data);
            }
            else {
              alert("Za izbrano obdobje še ni vnesenih podatkov.");
            }
          }
        })
      }
    }
});
