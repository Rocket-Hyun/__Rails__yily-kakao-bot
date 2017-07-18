
// 카카오톡 기록 사이트
var express = require('express');
var mongoose = require('mongoose');
// body-parser module를 bodyPaser 변수에 담습니다.
var bodyParser = require("body-parser");
//method-override module을 methodOverride변수에 담습니다.
var methodOverride = require("method-override");
var app = express();
var name_flag_array = new Array("");
var name_array = new Array("");
var kakaousers= '';
//2016-12-26 wit.ai 추가
var sendTextMessage = null;
var fbid = '1399985126708579';
let Wit = null;
let log = null;
try {
  // if running from repo
  Wit = require('../').Wit;
  log = require('../').log;
} catch (e) {
  Wit = require('node-wit').Wit;
  log = require('node-wit').log;
}


const sessions = {};

const findOrCreateSession = (fbid) => {
  let sessionId;
  // Let's see if we already have a session for the user fbid
  Object.keys(sessions).forEach(k => {
    if (sessions[k].fbid === fbid) {
      // Yep, got it!
      sessionId = k;
    }
  });
  if (!sessionId) {
    // No session found for user fbid, let's create a new one
    sessionId = new Date().toISOString();
    sessions[sessionId] = {fbid: fbid, context: {}};
  }
  console.log('**'+ sessionId);
  return sessionId;
};
function KakaoMessage(id, text){

  sendTextMessage = text;

  console.log("ID : " + id + " 대화내용 : "+ text);
}

const firstEntityValue = (entities, entity) => {
  console.log("****************4**************** ");
  const val = entities && entities[entity] &&
    Array.isArray(entities[entity]) &&
    entities[entity].length > 0 &&
    entities[entity][0].value
  ;
  if (!val) {
    return null;
  }
  return typeof val === 'object' ? val.value : val;
};

// Our bot actions
const actions = {
  send({sessionId}, {text}) {
    console.log("****************5**************** ");
    // Our bot has something to say!
    // Let's retrieve the Facebook user whose session belongs to
    const recipientId = sessions[sessionId].fbid;
    if (recipientId) {
      // Yay, we found our recipient!
      // Let's forward our bot response to her.
      // We return a promise to let our bot know when we're done sending
      return KakaoMessage(recipientId, text)
      .then(() => null)
      .catch((err) => {
        console.error(
          'Oops! An error occurred while forwarding the response to',
          recipientId,
          ':',
          err.stack || err
        );
      });
    } else {
      console.error('Oops! Couldn\'t find user for session:', sessionId);
      // Giving the wheel back to our bot
      return Promise.resolve()
    }
  },
  // You should implement your custom actions here
  getForecast({context, entities}) {
console.log("****************3**************** ");
    var location = firstEntityValue(entities, 'location');
    if (location) {
      context.forecast = 'sunny in ' + location; // we should call a weather API here
      delete context.missingLocation;
    } else {
      context.missingLocation = true;
      delete context.forecast;
    }

    return context;
  },
  // See https://wit.ai/docs/quickstart
};

// Setting up our bot
const wit = new Wit({
  accessToken: 'D4WQQTPGRJNN7ISEIPFB2ROM73P6AZ2G',
  actions,
  logger: new log.Logger(log.INFO)
});

//DB Setting : 환경 변수를 사용하여 MONGO_DB에 접속합니다.
mongoose.connect(process.env.MONGO_DB);
//mongoose의 DB Object를 가져와 db 변수에 넣습니다.
var db = mongoose.connection;
//DB가 성공적으로 연결 된 경우
db.once("open", function(){
  console.log("** MONGO_DB CONNECTED **");
});
//DB 연결 중 에러가 있는 경우
db.on('error', function(err){
  console.log("** DB CONNECTION ERR : **" ,err);
});
/*mongoose.Schema 함수를 사용해서 schema(data구조를 미리 정의해 놓는 것) object를 생성합니다.
사용할 Data의 형태를 object로 생성한 다음 mongoose.Schema함수에 넣습니다.
kakaomsg schema를 잠시 살펴보면 user_key, type, content 항목들을 가지고 있으며 새 항목 모두 타입은 String입니다.
나머지 사용가능한 schema type들은 mongoose  공식사이트(http://mongoosejs.com/docs/schematypes.html)에서 확인해 주세요.*/
var kakaomsgSchema = mongoose.Schema({
  user_key: {type: String},
  name: {type: String},
  type: {type: String},
  content: {type: String}
});
//mongoose.model함수를 사용하여 kakaomsg schema의 model을 생성합니다 kakaomsg에 일반적으로 s가 붙어서 테이블 생성
var Kakaomsg = mongoose.model("kakaomsg", kakaomsgSchema);

//user 관리를 위한 Schema를 생성합니다.
var kakaouserSchema = mongoose.Schema({
  user_key: {type: String, unique:true},
  name: {type: String},
  password: {type: String},
  email : {type: String},
  name_flag: {type: String},
  password_flag: {type: String},
  email_flag: {type: String}
});
//KakaoUser 변수로 테이블에 접근
var KakaoUser = mongoose.model("kakaouser", kakaouserSchema);

//PORT 지정하는 부분
app.set('port', (process.env.PORT || 5000));
//ejs파일을 사용하기 위해서는 res.render 함수를 사용해야 하며, 첫번째 parameter로 ejs의 이름을,
//두번째 parameter로 ejs에서 사용될 object를 전달합니다. res.render함수는 ejs를 /views 폴더에서 찾으므로 views폴더의 이름은 변경되면 안됩니다.
app.set("view engine", "ejs");
app.use(express.static(__dirname+"/"));
// bodyParser로 stream의 form data중  json data를 req.body에 옮겨 담습니다
app.use(bodyParser.json());
// bodyParser로 stream의 form data중  urlencoded data를 분석해서 req.body에 옮겨 담습니다
app.use(bodyParser.urlencoded({extended:true}));
//method의 query로 들어오는 값으로 HTTP method를 바꿉니다.
//예를들어 http://example.com/category/id?_method=delete를 받으면 _method의 값인 delete을 읽어 해당 request의 HTTP method를 delete으로 바꿉니다.
app.use(methodOverride("_method"));

//사이트 root로 이동하는 경우 /kakaomsgs로 redirect 해준다.
app.get("/", function(req, res){
 res.redirect("/kakaomsgs");
});
//root/kakaomsgs로 이동하는 경우. 내가 입력한 모든 Data를 찾아서 보여줍니다. kakaomsgs/index로 redirect 합니다.
app.get("/kakaomsgs",function(req, res){
  Kakaomsg.find({},function(err,kakaomsgs){
    if(err) return res.json(err);
    res.render("kakaomsgs/index", {kakaomsgs:kakaomsgs});
  });
});
// kakaomsgs/new"에 get 요청이 오는 경우 : 새로운 주소록을 만드는 form이 있는 views/kakaomsgs/new.ejs를 render합니다.
app.get("/kakaomsgs/new", function(req, res){
 res.render("kakaomsgs/new");
});
// views/kakaomsgs/new.ejs 에서 post로 접근 create는 post로만 가능하다. submit 버튼 누르면 날아옴
app.post("/kakaomsgs", function(req, res){
 Kakaomsg.create(req.body, function(err, kakaomsg){
  if(err) return res.json(err);
  res.redirect("/kakaomsgs");
 });
});

//req.params.id는 MONGO_DB에서 사용하는 ROWID 같은 개념이다.
// views/kakaomsgs/index.ejs 에서 herf로 접근 이름을 클릭하면 MONGO_DB _id를 return으로 날려준다.
app.get("/kakaomsgs/:id", function(req, res){
 Kakaomsg.findOne({_id:req.params.id}, function(err, kakaomsg){
  if(err) return res.json(err);
  res.render("kakaomsgs/show", {kakaomsg:kakaomsg});
  console.log('id' + req.params.id);
 });
});

// views/kakaomsgs/show.ejs  에서 herf로 접근. 한 개의 Data만 표출 되므로 따로 선택은 필요 없음
app.get("/kakaomsgs/:id/edit", function(req, res){
 Kakaomsg.findOne({_id:req.params.id}, function(err, kakaomsg){
  if(err) return res.json(err);
  res.render("kakaomsgs/edit", {kakaomsg:kakaomsg});
 });
});

// views/kakaomsgs/edit.ejs 에서
app.put("/kakaomsgs/:id", function(req, res){
 Kakaomsg.findOneAndUpdate({_id:req.params.id}, req.body, function(err, kakaomsg){
  if(err) return res.json(err);
  res.redirect("/kakaomsgs/"+req.params.id);
 });
});

// kakaomsgs - destroy // 7
app.delete("/kakaomsgs/:id", function(req, res){
 Kakaomsg.remove({_id:req.params.id}, function(err, kakaomsg){
  if(err) return res.json(err);
  res.redirect("/kakaomsgs");
 });
});

//KAKAO TALK
app.get('/keyboard', function(req, res) {
    res.send({
        "type": "buttons",
        "buttons": ["시작", "닉네임생성", "이동현님"]
    });
});

app.post('/message', function(req, res) {

  //접속 유저 초기화
    KakaoUser.create({
        user_key: req.body.user_key,
        name_flag: '0',
        password_flag: '0',
        email_flag: '0',
        name: '낯선손'
    }, function(error, doc) {});

    if (req.body.content === '시작') {
                res.send({
                            "message": {
                                  "text": "안녕하세요 반갑습니다. \n 웹, DB, 카카오톡 연동 서비스 구현 중입니다.\n 혹시 아직 닉네임이 없으시다면 생성 부탁 드립니다. \n(명령어:닉네임생성)"
                            }
                  });
    }

    //닉네임생성 버튼을 누르면
    if(req.body.content === '닉네임생성'){
        //닉네임 생성 스타트,
        KakaoUser.findOneAndUpdate({'user_key': req.body.user_key},{'name_flag':'1'},{new: true}, function(err, users) {
            if (err) {console.log("Something wrong when updating data!");}
            //이름 바꿨다는 뜻으로 name_flag
            obj = JSON.stringify(users); //객체 또는 배열을 인자로 받아 string을 json 형식으로 변경
            kakaousers = JSON.parse(obj); //json 파싱하기 위해 변수에 배정
        });

        res.send({
                    "message": {
                          "text": "닉네임생성 버튼을 누르셨습니다. \n사용하실 닉네임을 입력해 주세요."
                    }
                });

      }
      if(kakaousers.name_flag === '1'){
                  KakaoUser.findOneAndUpdate({'user_key': req.body.user_key}, {'name': req.body.content, 'name_flag':'3'},{new: true}, function(err, users) {
                              if (err) {console.log("Something wrong when updating data!");}
                              obj = JSON.stringify(users); //객체 또는 배열을 인자로 받아 string을 json 형식으로 변경
                              kakaousers = JSON.parse(obj); //json 파싱하기 위해 변수에 배정
                            });

                            //생성된 이름 표출
                            res.send({
                                        "message": {
                                              "text": "닉네임 생성이 완료 되었습니다.\n\n지금부터 입력하시는 대화 내용은 https://khj.herokuapp.com\n에 기록 됩니다. 입력 해 보세요."+
                                              "\n닉네임 변경을 원하시면 \n<<닉네임변경>>이라고 입력하세요."
                                        }
                    });
          }

        //닉네임설정 버튼을 누르면
        if (req.body.content === '닉네임변경') {
              //닉네임 변경 스타트,
              KakaoUser.findOneAndUpdate({'user_key': req.body.user_key},{'name_flag':'2'},{new: true}, function(err, users) {
                  if (err) {console.log("Something wrong when updating data!");}
                  obj = JSON.stringify(users); //객체 또는 배열을 인자로 받아 string을 json 형식으로 변경
                  kakaousers = JSON.parse(obj); //json 파싱하기 위해 변수에 배정
                  //이름 바꿨다는 뜻으로 name_flag`
              });

              //이름 바꿀 것인지 질문
              res.send({
                          "message": {
                                "text": "닉네임변경을 입력 하셨습니다. \n변경하실 닉네임을 입력해 주세요."
                          }
                      });
          }
          if(kakaousers.name_flag === '2'){
                  KakaoUser.findOneAndUpdate({'user_key': req.body.user_key}, {'name': req.body.content, 'name_flag':'3'},{new: true}, function(err, users) {
                              if (err) {console.log("Something wrong when updating data!");}
                              obj = JSON.stringify(users); //객체 또는 배열을 인자로 받아 string을 json 형식으로 변경
                              kakaousers = JSON.parse(obj); //json 파싱하기 위해 변수에 배정
                            });

                            //생성된 이름 표출
                            res.send({
                                        "message": {
                                              "text": "닉네임 변경이 완료 되었습니다.\n\n지금부터 입력하시는 대화 내용은 https://khj.herokuapp.com\n에 기록 됩니다. 입력 해 보세요."+
                                              "\n닉네임 변경을 원하시면 \n<<닉네임변경>>이라고 입력하세요."
                                        }
                    });
          }
          if(req.body.content === '이동현님'){
            res.send({//name_array.pop()
                                "message": {
                                      "text": "이게바로 카카오톡이다! 20170126 "
                                }
            });
          }

          if(kakaousers.name_flag !== '1' & kakaousers.name_flag !== '2' & req.body.content !== '닉네임변경' & req.body.content !== '닉네임생성' & req.body.content !== '시작'){

          //kakaousers 테이블에 접근
            KakaoUser.findOne({'user_key':req.body.user_key}, function (err, users) {
                  if (err) return res.json(err);
                  obj = JSON.stringify(users); //객체 또는 배열을 인자로 받아 string을 json 형식으로 변경
                  kakaousers = JSON.parse(obj); //json 파싱하기 위해 변수에 배정
            });
          res.send({//name_array.pop()
                              "message": {
                                    "text": kakaousers.name + "님. \n오늘은 여기까지만 할게요."+
                                    "\n\n<<닉네임변경>> 이라고 입력하시면 \n닉네임 변경 가능합니다. \n\n대화 내용은 \nhttps://khj.herokuapp.com\n에서 확인하세요."+
                                    "\n현재 wit.ai 연동 테스트 중 입니다.\n 2016-12-29일 페이스북 메신저 연동 성공. 조만간 카카오톡 메신저에 연동 해보겠습니다.\n\n"+
                                    "2017년 다들 새해 복 많이 받으세요~ :) 종무식이 늦게 끝나서 "
                              }
          });
          /*
          const sender = '1399985126708579';
          const sessionId = findOrCreateSession(sender);
        console.log("1");
          wit.runActions(
            sessionId, // the user's current session
            req.body.content, // the user's message
            sessions[sessionId].context // the user's current session state
          );
          console.log("2");
              res.send({//name_array.pop()
                                  "message": {
                                        "text": sendTextMessage
                                  }
              });*/
          Kakaomsg.create({
              user_key : req.body.user_key,
              type    : req.body.type,
              content: req.body.content
          }, function(error, doc) {
          });
        }



   res.sendStatus(200);
});

app.post('/friend', function(req, res) {
    res.sendStatus(200);
});

app.delete('/friend/:user_key', function(req, res) {
    res.sendStatus(200);
});

app.delete('/chat_room/:user_key', function(req, res) {
    res.sendStatus(200);
});


/******************************************************************************
//{nameQuery:'value'}를 뽑아주는 구문. 주소 끝에 ?nameQuery='value'써줘야 한다.
app.get("/hello", function(req,res){
 res.render("hello", {name:req.query.nameQuery});
console.log(req.query);
});
//파라미터에 입력하는 값을 name value로 넣는 구문
app.get("/hello/:nameParam", function(req,res){
 res.render("hello", {name:req.params.nameParam});
 console.log(req.query);
});
******************************************************************************/

/*
//Port Setting
app.listen(5000, function(){
  console.log("Server on!");
});
*/

// Spin up the server
app.listen(app.get('port'), function() {
    console.log('running on port', app.get('port'));
});
