class MessagesController < ApplicationController
  # 카톡봇 사용자의 키보드가 어떤 모습일지 선택
  def keyboard
    @response = {
      "type": "buttons",
      "buttons": ["와일리 이용하기", "와일리란?", "회원가입"]
    }
    render json: @response, status: :ok
  end

  def message
    # 메세지 중 '(' 가 들어가있는 뒷부분은 다 삭제
    @content = params[:content][/[^(]+/]

      ### 회원가입 && 비멤버십
      # 회원가입 단계
      # state_code[0]:0 >> 비멤버십 회원
      # state_code[5]:0 >> 휴대폰 번호를 아직 받지 않은 회원
      # state_code[5]:1 >> 휴대폰 번호를 받은 회원

      if @content == "와일리 이용하기"
      # 회원이면 state_code[5]를 0으로 변경
        yily_start_response

      # 와일리 정보 보기
      elsif @content == "와일리란?"
        yily_about_response

      elsif @content == "회원가입"
        # 신규가입일시 state_code[5] 기본값은 0
        sign_up_response

      # 회원가입 도중 취소했을시
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "0") && (@content == "취소")
        # 회원 탈퇴
        sign_up_cancel_response

      # 회원가입 > 번호를 입력 했을시
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "0")
        # if 번호가 맞다면~
          # 구글 닥스 응답
          google_docs_response
        # else
          # 제대로된 번호를 입력해주세요!
        # end

      ### 멤버십
      # 와일리 이용하기
      # state_code[0]:1 >> 멤버십 회원

      # state_code[2]:1 >> "바 정보 보기" 상태
      # state_code[2]:2 >> "오늘의 바우처 받기" 상태

      # state_code[5]:0 >> 바 미선택
      # state_code[5]:X >> 특정바 선택

      # 바 정보 보기
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@content == "바 정보 보기")
        store_list_show_response

      # 오늘의 바우처 받기
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@content == "오늘의 바우처 받기")
        store_list_show_response

      # 특정 바 입력 (정보용)
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "1")  && (@store = Store.find_by(name:@content))
        store_info_show_response

      # 특정바 > 내부사진 & 위치 & 메뉴보기 (준비중)
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "1")  && (@user.state_code[3..5] != "000") && (["내부 사진", "위치", "메뉴 보기"].include? @content)
        not_ready_response

      # 특정바 > 이용가능 칵테일 보기
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "1") && (@user.state_code[3..5] != "000") && (@content == "이용가능한 칵테일")
        drink_list_show_response

      # 특정바 > 이용가능 칵테일 > 특정 칵테일 보기
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "1") && (@store = Store.find_by(id: @user.state_code[3..5].to_i)) && (@drink = @store.drinks.find_by(name:@content))
        drink_info_show_response

      # 특정바 > 이용가능 칵테일 > 특정 칵테일 > 바우처 발급 받기
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "1") && (@store = Store.find_by(id: @user.state_code[3..5].to_i)) && (@drink = @store.drinks.find_by(id: @user.state_code[6..8].to_i)) && (@content == "바우처 받기")
        voucher_issue_response

      # 특정 바 입력 (바우처 용)
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "2") && (@store = Store.find_by(name:@content))
        drink_list_show_response

      # 특정 바 특정 칵테일 클릭 (바우처 용)
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[2] == "2") && (@store = Store.find_by(id: @user.state_code[3..5].to_i)) && (@drink = @store.drinks.find_by(name:@content))
        ## 바우처 발급!
        voucher_issue_response

      # 내 바우처
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@content == "내 바우처")
        voucher_show_response

      # 바우처 직원 사용 버튼 응답
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[1] == "1") && (@user.state_code[2] == "3")  && (@content == "[직원용] 바우처 사용하기")
        voucher_confirm_response

      #바우처 취소하기 응답
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[1] == "1") && (@user.state_code[2] == "3") && (@content == "바우처 취소하기")
        voucher_cancel_response

      # 바우처 최종 사용 응답
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[1] == "1") && (@user.state_code[2] == "4")  && (@content == "확인")
        voucher_use_response

      # 바우처 사용 후 평가 응답
      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@user.state_code[1] == "2") && (@user.state_code[2] == "4")
        voucher_rating_response

      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@content == "뒤로가기")
        return_response

      elsif (@user = User.find_by(user_key:params[:user_key])) && (@user.state_code[0] == "1") && (@content == "메인으로")
        main_response

      else
        etc
      end
  end

  # 카톡방 삭제시 회원탈퇴
  def delete
    if @user = User.find_by(user_key:params[:user_key])
      @user.destroy
    else

    end
    render nothing: true, status: :ok
  end

  private

    ## 0단계 응답

    # "와일리 이용하기" 클릭시 사용자 인증 / 비회원시 응답
    def yily_start_response
      # 가입한 유저인지 확인
      logger.info "[LINE:#{__LINE__}] 가입한 유저인지 확인 중 ..."
      if  @user = User.find_by(user_key: params[:user_key])
        logger.info "[LINE:#{__LINE__}] 가입한 유저 확인, 가입을 정상적으로 완료했는지 확인 중..."
        # 가입 도중임
        # 가입은 했지만 멤버십은 아님
        if @user.is_premium == false
          # 가입 도중인지 확인
          if @user.state_code[5] == "0"
            logger.info "[LINE:#{__LINE__}] 가입 도중인 유저임 / 통신종료"
            @response = {
              "message": {
                  "text": "죄송합니다. 와일리는 가입한 고객만 이용하실 수 있습니다.",
                  "message_button": {
                    "label": "와일리 알아보기",
                    "url": "https://www.facebook.com/theyily/"
                  }
              },
              "keyboard": {
                "type": "buttons",
                "buttons": [
                  "와일리 이용하기",
                  "와일리란?",
                  "회원가입"
                ]
              }
            }
            render json: @response, status: :ok

          # 가입은 했지만 멤버십은 아님
          else
            logger.info "[LINE:#{__LINE__}] 가입은 했지만 멤버십은 아님 / 통신종료"
            @response = {
                "message": {
                    "text": "안녕하세요! 아직 멤버십 확정을 받지 못하셨습니다.\n조금만 기다려주세요!\n구글 독스를 안하셧다면 다시 해보세요!\n\n문의사항이 있으시면 채팅창 오른쪽에 있는 1:1 버튼으로 문의주세요!"
                },
                "keyboard": {
                  "type": "buttons",
                  "buttons": [
                    "와일리 이용하기",
                    "와일리란?",
                    "회원가입"
                  ]
                }
            }
            render json: @response, status: :ok
          end

        # 정상적으로 가입한 멤버십 유저
        else
          logger.info "[LINE:#{__LINE__}] 가입도 했고 멤버십임, 통과!"

          # 바우처를 최소 1회 받은 적이 있고, 마지막 바우처의 날짜가 지금 날짜보타 이전일 때 state_code[1]을 0으로 변경
          if @user.vouchers.count != 0 && ((@user.vouchers.last.created_at).to_date < (Time.now - 6.hours).to_date)
            @user.state_code[1] = "0"
          end

          # state_code[3..5] 0으로 변경 (바선택 X)
          @user.state_code[3..5] = "000"

          # state_code[2] 0으로 변경 (메인 페이지)
          @user.state_code[2] = "0"
          @user.save

          @response = {
            "message": {
                "text": "#{@user.name}님 환영합니다!\n오늘의 와일리를 즐기세요!\n>최근 술:3일전
                "
            },
            "keyboard": {
              "type": "buttons",
              "buttons": [
                "바 정보 보기",
                "오늘의 바우처 받기",
                "내 바우처"
              ]
            }
          }
          render json: @response, status: :ok
        end
      # 비회원
      else
        logger.info "[LINE:#{__LINE__}] 신규 유저임, 가입해야함 / 통신종료"
        @response = {
            "message": {
                "text": "죄송합니다. 와일리는 가입한 고객만 이용하실 수 있습니다.",
                "message_button": {
                  "label": "와일리 알아보기",
                  "url": "https://www.facebook.com/theyily/"
                }
            },
            "keyboard": {
              "type": "buttons",
              "buttons": [
                "와일리 이용하기",
                "와일리란?",
                "회원가입"
              ]
            }
        }
        render json: @response, status: :ok
      end
    end

    # "와일리란?" 클릭시 응답
    def yily_about_response
      @response = {
          "message": {
              "text": "와일리는 프리미엄 멤버십입니다.",
              "message_button": {
                "label": "와일리 알아보기",
                "url": "https://www.facebook.com/theyily/"
              }
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "와일리 이용하기",
              "와일리란?",
              "회원가입"
            ]
          }
      }
      render json: @response, status: :ok
    end

    # "회원가입" 클릭시 응답
    def sign_up_response
      # 가입한 유저인지 확인
      logger.info "[LINE:#{__LINE__}] 가입한 유저인지 확인 중 ..."
      if  (@user = User.find_by(user_key: params[:user_key]))&& @user.state_code[0] == "1"
        # 정상적으로 회원 가입한 유저
          logger.error "[LINE:#{__LINE__}] 기존 회원 확인, 회원가입 취소 / 통신 종료"
          @response = {
              "message": {
                  "text": "이미 회원가입을 완료하셨습니다!"
              },
              "keyboard": {
                "type": "buttons",
                "buttons": [
                  "와일리 이용하기",
                  "와일리란?",
                  "회원가입"
                ]
              }
          }
          render json: @response, status: :ok

      # 비회원 또는 회원인데 번호 입력을 안했을때만 회원가입 진행
      else
        logger.error "[LINE:#{__LINE__}] 비회원 확인, 휴대폰 번호 요구 / 통신 종료"
        # 이미 회원인데 번호가 있으면 유저를 생성하지 않음
        User.find_or_create_by(user_key:params[:user_key])
        @response = {
            "message": {
                # "text": "#{@user.name}님, 환영합니다! 바를 선택해주세요."
                "text": "회원가입을 위한 휴대폰번호 인증이 필요합니다. 번호를 입력해주세요.(예: 0100000000) \n\n 가입을 취소하시려면 '취소'라고 말해주세요."
            },
            "keyboard": {
              "type": "text"
            }
        }
        render json: @response, status: :ok

      end
    end

    # "회원가입 > 번호입력" 시 응답
    def google_docs_response
      logger.error "[LINE:#{__LINE__}] 휴대폰 번호 확인, 구글 독스 응답 / 통신 종료"

      # 휴대폰 번호를 받아야 state_code[5]이 0 -> 1로 수정
      @user.state_code[5] = "1"
      @user.number = @content
      @user.save
      @response = {
          "message": {
              "text": "와일리는 시즌로만 받고있습니다. 아래 링크의 설문지를 채워주시면 입력하신 번호로 연락드리겠습니다.\n",
              "message_button": {
                "label": "설문지 바로가기",
                "url": "https://docs.google.com/a/u.sogang.ac.kr/forms/d/e/1FAIpQLSccnOYj3fC8mrhVnzhqaa7CWnrmmzC5dhOsyQqjPauFNCIJfg/viewform"
              }
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "와일리 이용하기",
              "와일리란?",
              "회원가입"
            ]
          }
      }
      render json: @response, status: :ok
    end

    # 회원가입 취소시 응답
    def sign_up_cancel_response
      logger.info "[LINE:#{__LINE__}] 회원탈퇴 중..."
      @user.destroy
      @response = {
          "message": {
              "text": "
               회원 가입이 취소 되었습니다!
              "
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "와일리 이용하기",
              "와일리란?",
              "회원가입"
            ]
          }
      }
      render json: @response, status: :ok
    end

    # 없는 명령어 응답
    def etc
      @response = {
          "message": {
              "text": "잘못된 명령어 입니다. 다시 입력해주세요."
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
                "와일리 이용하기",
                "와일리란?",
                "회원가입"
            ]
          }
      }
      render json: @response, status: :ok
    end

    ## 1단계 응답

    #  바 정보 보기 응답
    def store_list_show_response
      logger.info "[LINE:#{__LINE__}] 바 리스트 보기 응답 중... 정보용 쿠폰용인지 확인 중..."
      if @content == "바 정보 보기" || (@content == "뒤로가기" && @user.state_code[2] == "1")
        logger.info "[LINE:#{__LINE__}] 정보용 확인, 바 리스트 응답 / 통신 종료"
        @user.state_code[2] = "1"
      else
        logger.info "[LINE:#{__LINE__}] 쿠폰용 확인, 바 리스트 응답 / 통신 종료"
        @user.state_code[2] = "2"
      end
        @user.state_code[3..5] = "000"
        @user.save

        # 바 개수만큼 버튼 생성
        @buttons = Array.new
        t = Time.now

        Store.all.each do |store|
          # 평일 쿠폰 수량 반영
          if t.on_weekday?
            @buttons << "#{store.name}(#{store.weekday_voucher-store.today_vouchers.count}개)"
          else
          # 주말 쿠폰 수량 반영
            @buttons << "#{store.name}(#{store.weekend_voucher-store.today_vouchers.count}개)"
          end
        end
        @buttons << "뒤로가기"

        @response = {
            "message": {
                "text": "바를 선택해주세요."
            },
            "keyboard": {
              "type": "buttons",
              "buttons": @buttons
            }
        }
        render json: @response, status: :ok
    end

    # 특정바 선택시 응답(정보용)
    def store_info_show_response
      @store_id = format("%03d", @store.id)[-3..-1]
      @user.state_code[3..5] = @store_id
      @user.state_code[6..8] = "000"
      @user.save

      @response = {
          "message": {
              "text": "<#{@store.name}>\n#{@store.desc}"
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "내부 사진",
              "위치",
              "이용가능한 칵테일",
              "메뉴 보기",
              "뒤로가기"
            ]
          }
      }
      render json: @response, status: :ok
    end

    # 특정바에서 이용가능한 칵테일 선택시  OR 특정바 선택시 응답(바우처용)
    def drink_list_show_response
      if @user.state_code[2] == "1"
        logger.info "[LINE:#{__LINE__}] 특정바(정보용)에서 음료 리스트 나열 / 통신종료"
        @store = Store.find(@user.state_code[3..5].to_i)
      elsif @user.state_code[2] == "2"
        logger.info "[LINE:#{__LINE__}] 특정바(바우처용)에서 음료 리스트 나열 / 통신종료"
        @store_id = format("%03d", @store.id)[-3..-1]
        @user.state_code[3..5] = @store_id
        @user.save
      else
        logger.info "[LINE:#{__LINE__}] 알 수 없는 에러 / 통신종료"
        return
      end


      # 해당바의 칵테일 개수만큼 버튼 생성
      @buttons = Array.new
      @store.drinks.each do |drink|
        @buttons << drink.name
      end
      @buttons << "뒤로가기"



      @response = {
          "message": {
              "text": "<#{@store.name}>의 칵테일들 입니다."
          },
          "keyboard": {
            "type": "buttons",
            "buttons": @buttons
          }
      }
      render json: @response, status: :ok
    end

    # 특정바(정보용)에서 특정 칵테일 선택시 응답
    def drink_info_show_response
      logger.info "[LINE:#{__LINE__}] 특정바(바우처용)에서 특정 칵테일 선택, 칵테일 관련 정보버튼 응답 / 통신종료"
      @drink_id = format("%03d", @drink.id)[-3..-1]
      @user.state_code[6..8] = @drink_id
      @user.save

      @response = {
          "message": {
              "text": "<#{@store.name}의 #{@drink.name}> #{@drink.desc}"
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "바우처 받기",
              "뒤로가기"
            ]
          }
      }
      render json: @response, status: :ok

    end

    # 바우처 발급 응답
    def voucher_issue_response
      logger.info "[LINE:#{__LINE__}] 바우처 발급 응답, 바우처를 이미 발급 받았는지 확인 중 ..."

      # case1) 아직 쿠폰을 발급받지 않았을 때
      if @user.state_code[1] == "0"
        logger.info "[LINE:#{__LINE__}] 바우처 미발급 유저 확인, 바에 남은 바우처 수량이 있는지 확인 중..."

        # 바에 남은 바우처 수량이 있을 때
        if @store.vouchers_left_size > 0
          logger.info "[LINE:#{__LINE__}] 바우처 수량 확인, 바우처 발급 완료 / 통신종료"
          # 오전 6시까지 발급 받은 것을 이전 날 바우쳐로 쳐줌
          @voucher = Voucher.create(user_id:@user.id, drink_id:@drink.id, created_at: Time.now.in_time_zone - 6.hours)
          @user.state_code[1] = "1"
          @user.save

          @response = {
              "message": {
                  "text": "바우처가 발급됨!"
              },
              "keyboard": {
                "type": "buttons",
                "buttons": [
                  "메인으로"
                ]
              }
          }
          render json: @response, status: :ok
        # 바에 남은 수량이 없을 때
        else
          logger.info "[LINE:#{__LINE__}] 바우처 수량 부족, 바우처 미발급 / 통신종료"

          @response = {
              "message": {
                  "text": "오늘의 #{@store.name} 바우처 수량이 모두 매진 됐습니다! 다른 바를 이용해주세요!"
              },
              "keyboard": {
                "type": "buttons",
                "buttons": [
                  "뒤로가기"
                ]
              }
          }
          render json: @response, status: :ok
        end


      # case2) 쿠폰을 발급 받은 상태일 때
      elsif @user.state_code[1] == "1"
        logger.info "[LINE:#{__LINE__}] 바우처 발급 유저, already 메세지 띄우고 바우처 미발급 / 통신종료"

        @response = {
            "message": {
                "text": "이미 바우처를 발급 받으셨습니다! 내 바우처를 확인하세요."
            },
            "keyboard": {
              "type": "buttons",
              "buttons": [
                "뒤로가기"
              ]
            }
        }
        render json: @response, status: :ok


      # case3) 오늘의 쿠폰을 사용한 상태일 때
      elsif @user.state_code[1] == "2"
        logger.info "[LINE:#{__LINE__}] 바우처 사용 유저, already 메세지 띄우고 바우처 미발급 / 통신종료"

        @response = {
            "message": {
                "text": "이미 오늘의 바우처를 사용하셨습니다! 내일을 기대해주세요 :)"
            },
            "keyboard": {
              "type": "buttons",
              "buttons": [
                "뒤로가기"
              ]
            }
        }
        render json: @response, status: :ok

      end
    end

    # 바우처 확인 응답
    def voucher_show_response
      logger.info "[LINE:#{__LINE__}] 바우처 확인 응답, 오늘의 바우처를 발급 받았는지 확인 중 ..."
      @user.state_code[2] = "3"
      @user.save

      # 최소 1개의 바우처는 받아봄
      if @voucher = @user.vouchers.last
        logger.info "[LINE:#{__LINE__}] 최소 1개의 바우처는 받아 봄, 마지막 바우처가 오늘 것인지 확인 중..."

        # 바우처가 오늘 받은 것일때
        if @voucher.created_at.to_date == (Time.now - 6.hours).to_date
        logger.info "[LINE:#{__LINE__}] 바우처가 오늘 것임, 바우처사 사용한 것인지 확인 중..."

          # 바우처가 사용하지 않은 것일 때
          if !@voucher.is_used
            logger.info "[LINE:#{__LINE__}] 바우처가 아직 미사용임 / 통신종료"

            @response = {
                "message": {
                    "text": "#{(Time.now - 6.hours).to_date}의 바우처\n> Bar: #{@voucher.drink.store.name} \n> Drink: #{@voucher.drink.name}"
                },
                "keyboard": {
                  "type": "buttons",
                  "buttons": [
                    "[직원용] 바우처 사용하기",
                    "바우처 취소하기",
                    "뒤로가기"
                  ]
                }
            }
            render json: @response, status: :ok


          # 바우처가 사용한 것일 때
          else
            logger.info "[LINE:#{__LINE__}] 바우처가 사용한 것임 / 통신종료"
            @response = {
                "message": {
                    "text": "#{(Time.now - 6.hours).to_date}의 바우처는 이미 사용하셨습니다. 내일을 기대해주세요 :)"
                },
                "keyboard": {
                  "type": "buttons",
                  "buttons": [
                    "뒤로가기"
                  ]
                }
            }
            render json: @response, status: :ok
          end

        # 바우처가 오늘 받은 것이 아닐 때
        else
          logger.info "[LINE:#{__LINE__}] 마지막 바우처가 오늘 받은 것이 아님 / 통신종료"
          @voucher = @user.vouchers.last

          @response = {
              "message": {
                  "text": "#{(Time.now - 6.hours).to_date}의 바우처를 받지 않으셨습니다! 받아주세요!"
              },
              "keyboard": {
                "type": "buttons",
                "buttons": [
                  "뒤로가기"
                ]
              }
          }
          render json: @response, status: :ok
        end
      # 한번도 바우처를 안받아 봤을 때
      else
        logger.info "[LINE:#{__LINE__}] 한 번도 바우처를 받아 본적이 없음 / 통신종료"
        @response = {
            "message": {
                "text": "#{(Time.now - 6.hours).to_date}의 바우처를 받지 않으셨습니다! 받아주세요!"
            },
            "keyboard": {
              "type": "buttons",
              "buttons": [
                "뒤로가기"
              ]
            }
        }
        render json: @response, status: :ok
      end

    end

    # 바우처 사용 확인 응답
    def voucher_confirm_response
      logger.info "[LINE:#{__LINE__}] [직원용] 바우처 사용 확인 클릭 / 통신종료"
      @user.state_code[2] = "4"
      @user.save

      @response = {
          "message": {
              "text": "<#{@user.vouchers.last.drink.store.name}>의 #{@user.vouchers.last.drink.name} 바우처가 맞는지 확인해주세요!\n정말로 사용하시겠습니까?(잘못 사용시 본인 책임)"
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "확인",
              "뒤로가기"
            ]
          }
      }
      render json: @response, status: :ok
    end

    # 바우처 최종 사용 응답
    def voucher_use_response
      logger.info "[LINE:#{__LINE__}] 바우처 최종 사용 '예' 클릭 / 통신종료"
      @voucher = @user.vouchers.last
      @voucher.is_used = true
      @voucher.save

      @user.state_code[1] = "2"
      @user.save

      @response = {
          "message": {
              "text": "와일리를 이용해주셔 감사합니다! 방문하신 바를 평가해주시겠어요?"
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "★★★★★",
              "★★★★",
              "★★★",
              "★★",
              "★"
            ]
          }
      }
      render json: @response, status: :ok
    end

    def voucher_rating_response
      logger.info "[LINE:#{__LINE__}] 바우처 평가 완료, 메인으로 / 통신종료"
      @voucher = @user.vouchers.last
      # 바우처에 점수 메기기
      @voucher.rating = @content.size
      @voucher.save

      yily_start_response
    end

    # 바우처 취소 응답
    def voucher_cancel_response
      logger.info "[LINE:#{__LINE__}] 바우처 취소 완료, 메인으로 / 통신종료"

      # 마지막 바우처 삭제
      @voucher = @user.vouchers.last
      @voucher.destroy

      # 바우처 미발급 상태로 바꾸기
      @user.state_code[1] = "0"
      # 바우처 발급용 바 리스트 선택으로 응답
      @user.state_code[2] = "2"
      @user.save

      # 바 개수만큼 버튼 생성
      @buttons = Array.new
      t = Time.now
      # 지금 시간에서 9시간을 빼면 created_at 시임
      # date = (Time.now-9.hours).beginning_of_day
      Store.all.each do |store|
        # 평일 쿠폰 수량 반영
        if t.on_weekday?
          @buttons << "#{store.name}(#{store.weekday_voucher-store.today_vouchers.count}개)"
        else
        # 주말 쿠폰 수량 반영
          @buttons << "#{store.name}(#{store.weekend_voucher-store.today_vouchers.count}개)"
        end
      end
      @buttons << "뒤로가기"

      @response = {
          "message": {
              "text": "바우처가 취소 됐습니다! 새로 바우처를 발급받을 바를 선택해주세요."
          },
          "keyboard": {
            "type": "buttons",
            "buttons": @buttons
          }
      }
      render json: @response, status: :ok
    end

    #  뒤로가기 응답
    def return_response
      # 현재 상태가 "바 정보 보기"
      # 이전 상태가 메인
      if @user.state_code[2] == "1" && @user.state_code[3..5] == "000"
        main_response

      # 현재 상태가 "바코드" >> "내부 사진", "위치", "메뉴", "이용가능 음료"
      # 이전 상태가 "바 정보 보기"
      elsif @user.state_code[2] == "1" && @user.state_code[3..5] != "000" && @user.state_code[6..8] == "000"
        store_list_show_response

      # 현재 상태가 "칵테일을 선택"
      # 이전 상태가 "바코드"
      elsif @user.state_code[2] == "1" && @user.state_code[3..5] != "000" && @user.state_code[6..8] != "000"
        store_info_show_response

      # 현재 상태가 "오늘의 바우처 받기"
      # 이전 상태가 메인
      elsif @user.state_code[2] == "2" && @user.state_code[3..5] == "000"
        main_response

      # 현재 상태가 "바코드"
      # 이전 상태가 "오늘의 바우처 받기"
      elsif @user.state_code[2] == "2" && @user.state_code[3..5] != "000" && @user.state_code[6..8] == "000"
        main_response



      # 현재 상태가 "내 바우처"
      # 이전 상태가 메인
      elsif @user.state_code[2] =="3"
        main_response

      # 현재 상태가 "[직원용] 바우처 사용 확인"
      # 이전 상태가 "내 바우처"
      elsif @user.state_code[2] == "4"
        voucher_show_response

      # 나머지는 걍 메인으로
      else
        main_response
      end
    end

    # 메인으로 가는 응답
    def main_response
      logger.info "[LINE:#{__LINE__}] 메인으로 이동 / 통신종료"

      # 바우처를 최소 1회 받은 적이 있고, 마지막 바우처의 날짜가 지금 날짜보타 이전일 때 state_code[1]을 0으로 변경
      if @user.vouchers.count != 0 && ((@user.vouchers.last.created_at).to_date < (Time.now - 6.hours).to_date)
        @user.state_code[1] = "0"
      end

      @user.state_code[2] = "0"
      @user.state_code[3..8] = "000000"
      @user.save
      @response = {
        "message": {
            "text": "#{@user.name}님 환영합니다!\n오늘의 와일리를 즐기세요!\n>최근 술:3일전
            "
        },
        "keyboard": {
          "type": "buttons",
          "buttons": [
            "바 정보 보기",
            "오늘의 바우처 받기",
            "내 바우처"
          ]
        }
      }
      render json: @response, status: :ok
    end

    def not_ready_response
      logger.info "[LINE:#{__LINE__}] 아직 준비중인 메뉴, 바 메뉴로 이동 / 통신종료"
      @store = Store.find(@user.state_code[3..5].to_i)
      @response = {
          "message": {
              "text": "<#{@store.name}>의 아직 준비 중인 버튼입니다!"
          },
          "keyboard": {
            "type": "buttons",
            "buttons": [
              "내부 사진",
              "위치",
              "이용가능한 칵테일",
              "메뉴 보기",
              "뒤로가기"
            ]
          }
      }
      render json: @response, status: :ok
    end

end
