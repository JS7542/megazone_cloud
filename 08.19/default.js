$().ready(function(){
    let jsonData;

    /* ##############################################################################################
        교육생의 성적리스트 반환
    =============================================================================================== */
    function resultLoad(uid) {
        $("#resultArea tr").remove();
        if(!uid) uid="";

        $.ajax({
            url: "/api/scores",
            method: "GET",
            dataType: "json",

            success: function(data) {
                let jsonList = data.data || [];

                // 교육생 선택 시 해당 교육생 데이터만 표시
                if(uid !== "") {
                    jsonList = jsonList.filter(function(row) {
                        return row.fid === uid;
                    });
                }

                for(let row in jsonList) {
                    let item = jsonList[row];
                    let idx = item.fidx;

                    let $tr = $("<tr></tr>");

                    let $chkTd = $("<td></td>");
                    let $chkbox = $("<input />");
                    $chkbox.prop("type", "checkbox");
                    $chkbox.prop("name", "idx");
                    $chkbox.val(idx);
                    $chkTd.append($chkbox);
                    $tr.append($chkTd);

                    $tr.append($("<td></td>").text(item.fid));
                    $tr.append($("<td></td>").text(item.fname));
                    $tr.append($("<td></td>").text(item.fgender));
                    $tr.append($("<td></td>").text(item.kor));
                    $tr.append($("<td></td>").text(item.eng));
                    $tr.append($("<td></td>").text(item.mat));
                    $tr.append($("<td></td>").text(item.total));
                    $tr.append($("<td></td>").text(item.average));
                    $tr.append($("<td></td>").text(item.test_date));

                    let $td = $("<td><a class=\"mp\" title=\"삭제\">Delete</a></td>");
                    $td.children("a").prop("idx", idx);
                    $tr.append($td);

                    $("#resultArea").append($tr);
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);
            }
        });
    }


    // 교육생의 성적 리스트 반환 함수 최초 자동 실행
    resultLoad();


    /* ##############################################################################################
        불러오기 버튼을 클릭하면 교육생 데이터를 반환받아 Select box에 표현
    =============================================================================================== */
    $("#btnReload").on("click", function() {
        $("#uid option").remove();
        $("#uid").append("<option value=\"\">==== 교육생 선택 ====</option>");

        $.ajax({
            url: "/api/students",
            method: "GET",
            dataType: "json",

            success: function(data) {
                let jsonList = data.data || [];

                for(let row in jsonList) {
                    let $option = $("<option></option>");
                    $option.val(jsonList[row]["fid"]);
                    $option.text(jsonList[row]["fname"]);
                    $("#uid").append($option);
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);
            }
        });
    });

    $("#btnReload").click();
    $("#btnReload").prop("disabled", true);


    /* ##############################################################################################
        교육생 이름을 선택할 경우 성적 리스트에 선택한 교육생의 성적만 표현
    =============================================================================================== */
    $("#uid").on("change", function() {
        let uid = $(this).val();

    // 선택한 학생의 성적 목록 표시
        resultLoad(uid);

    // 학생 선택 해제 시 초기화
        if(uid === "") {
            $("#idx").val("");
            $("#kor").val(0);
            $("#eng").val(0);
            $("#mat").val(0);
            return;
        }

    // 선택한 학생의 기존 성적 조회
        $.ajax({
            url: "/api/scores",
            method: "GET",
            dataType: "json",

            success: function(data) {
                let scoreList = data.data || [];

                // 선택한 학생의 성적 찾기
                let score = scoreList.find(function(item) {
                    return item.fid === uid;
                });

                if(score) {
                // 기존 성적이 있으면 값 불러오기
                    $("#idx").val(score.fidx);
                    $("#kor").val(score.kor);
                    $("#eng").val(score.eng);
                    $("#mat").val(score.mat);
                }
                else {
                // 기존 성적이 없으면 0으로 초기화
                    $("#idx").val("");
                    $("#kor").val(0);
                    $("#eng").val(0);
                    $("#mat").val(0);
            }
        },

        error: function(request, status, error) {
            console.log("성적 조회 실패");
            console.log("code:" + request.status);
            console.log("message:" + request.responseText);
            console.log("error:" + error);

            // 조회 실패 시에도 이전 학생 점수가 남지 않도록 초기화
            $("#idx").val("");
            $("#kor").val(0);
            $("#eng").val(0);
            $("#mat").val(0);
            }
        });
    });


    /* ##############################################################################################
        반드시 0~100사이의 숫자만 입력 할 수 있게 제어
    =============================================================================================== */
    $(document).on("keyup change", "#kor, #eng, #mat", function(){
        if($(this).val() < 0 || $(this).val() > 100) {
            alert("점수는 0점 이상 100점 이하로만 입력해야 합니다.");
            $(this).val(0);
        }
    });


    /* ##############################################################################################
        성적 등록 버튼을 클릭한 경우
        POST /api/scores
    =============================================================================================== */
    $(document).on("click", "#btnLogin", function(){
        if($("#uid").val() == "") {
            alert("성적을 등록할 교육생을 선택하셔야 합니다.");
            $("#uid").focus();
            return;
        }

        if($("#kor").val() == "") {
            alert("국어 점수를 입력해주세요");
            $("#kor").focus();
            return;
        }

        if($("#eng").val() == "") {
            alert("영어 점수를 입력해주세요");
            $("#eng").focus();
            return;
        }

        if($("#mat").val() == "") {
            alert("수학 점수를 입력해주세요");
            $("#mat").focus();
            return;
        }

        $.ajax({
            url: "/api/scores",
            method: "POST",
            contentType: "application/json",
            dataType: "json",

            data: JSON.stringify({
                fid: $("#uid").val(),
                kor: Number($("#kor").val()),
                eng: Number($("#eng").val()),
                mat: Number($("#mat").val())
            }),

            success: function(data) {
                if(data["status"] == "success") {
                    alert(data["message"] || "성적이 등록되었습니다.");
                    resultLoad();
                }
                else {
                    alert("성적 등록 중 오류가 발생했습니다.");
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);

                let message = "성적 등록 중 오류가 발생했습니다.";

                if(request.responseJSON && request.responseJSON.detail) {
                    message = request.responseJSON.detail;
                }

                alert(message);
            }
        });
    });


    /* ##############################################################################################
        결과보기 버튼을 클릭한 경우
    =============================================================================================== */
    $(document).on("click", "#btnLoding", function(){
        resultLoad();
    });


    /* ##############################################################################################
        목록 헤더의 체크박스를 통한 모두 선택 또는 모두 해제
    =============================================================================================== */
    $("#allChecked").on("change", function() {
        $("input[name=idx]").prop("checked", this.checked);
    });


    /* ##############################################################################################
        개별 삭제
        DELETE /api/scores/{fidx}
    =============================================================================================== */
    $(document).on("click", ".mp", function(ev) {
        ev.stopPropagation();

        let idx = $(this).prop("idx");
        let $parentTR = $(this).closest("tr");
        let chk = $parentTR
            .children("td:first-child")
            .children("input")
            .prop("checked");

        if(!chk) {
            alert("선택한 목록이 없습니다. 목록의 체크박스에 체크를 해야합니다.");
            return;
        }

        if(!confirm("선택한 성적을 삭제하시겠습니까?")) {
            return;
        }

        $.ajax({
            url: "/api/scores/" + idx,
            method: "DELETE",
            dataType: "json",

            success: function(data) {
                if(data["status"] == "success") {
                    $parentTR.remove();
                }
                else {
                    alert("성적을 삭제중 에러가 발생하였습니다.");
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);
                alert("성적 삭제 중 오류가 발생했습니다.");
            }
        });
    });

/* ##############################################################################################
    수정할 성적 정보를 입력폼에 반영
=============================================================================================== */
function setScoreForm($tr) {

    let idx = $tr.children("td:first-child").children("input").val();
    let uid = $tr.children("td:nth-child(2)").text();
    let kor = $tr.children("td:nth-child(5)").text();
    let eng = $tr.children("td:nth-child(6)").text();
    let mat = $tr.children("td:nth-child(7)").text();

    $("#idx").val(idx);
    $("#uid").val(uid);
    $("#kor").val(kor);
    $("#eng").val(eng);
    $("#mat").val(mat);
}


/* ##############################################################################################
    행 클릭
=============================================================================================== */
$(document).on("click", "#resultArea tr", function(ev) {

    if($(ev.target).is("input, a")) return;

    setScoreForm($(this));
});


/* ##############################################################################################
    체크박스 클릭
=============================================================================================== */
$(document).on("change", "#resultArea input[name=idx]", function() {

    if($(this).prop("checked")) {
        setScoreForm($(this).closest("tr"));
    }

});


    /* ##############################################################################################
        수정
        PUT /api/scores/{fidx}
    =============================================================================================== */
    $(document).on("click", "#btnChoEdit", function(){
        let idx = $("#idx").val();

        if(idx == "") {
            alert("수정할 성적 목록의 행을 먼저 선택해주세요.");
            return;
        }

        if($("#uid").val() == "") {
            alert("교육생을 선택해주세요.");
            return;
        }

        $.ajax({
            url: "/api/scores/" + idx,
            method: "PUT",
            contentType: "application/json",
            dataType: "json",

            data: JSON.stringify({
                fid: $("#uid").val(),
                kor: Number($("#kor").val()),
                eng: Number($("#eng").val()),
                mat: Number($("#mat").val())
            }),

            success: function(data) {
                if(data["status"] == "success") {
                    alert(data["message"] || "성적이 수정되었습니다.");
                    resultLoad();
                }
                else {
                    alert("성적을 수정중 에러가 발생하였습니다.");
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);
                alert("성적 수정 중 오류가 발생했습니다.");
            }
        });
    });


    /* ##############################################################################################
        일괄삭제
        DELETE /api/scores
    =============================================================================================== */
    $(document).on("click", "#btnChoDel", function(){
        let selected = [];

        $("input[name=idx]:checked").each(function(){
            selected.push(Number($(this).val()));
        });

        if(selected.length == 0) {
            alert("삭제할 성적을 선택해주세요.");
            return;
        }

        if(!confirm(selected.length + "개의 성적을 삭제하시겠습니까?")) {
            return;
        }

        $.ajax({
            url: "/api/scores",
            method: "DELETE",
            contentType: "application/json",
            dataType: "json",

            data: JSON.stringify({
                fidx_list: selected
            }),

            success: function(data) {
                if(data["status"] == "success") {
                    alert(data["message"] || "성적이 삭제되었습니다.");
                    resultLoad();
                }
                else {
                    alert("성적 일괄삭제 중 에러가 발생하였습니다.");
                }
            },

            error: function(request, status, error) {
                console.log(request);
                console.log("code:" + request.status);
                console.log("message:" + request.responseText);
                console.log("error:" + error);
                alert("성적 일괄삭제 중 오류가 발생했습니다.");
            }
        });
    });

});