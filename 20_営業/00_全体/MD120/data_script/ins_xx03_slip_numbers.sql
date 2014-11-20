set linesize 1000
set pagesize 100

-- ***********************************
-- 実行前テーブル情報
-- ***********************************
PROMPT ##### xx03_slip_numbers PRE INSERT Info #####>>>
SELECT *
FROM   xx03_slip_numbers;


-- ***********************************
-- AP_FND_017 セットアップスクリプト
-- ***********************************
DECLARE
    ln_org_id            hr_all_organization_units.ORGANIZATION_ID%TYPE := NULL;
    ln_max_slip_num_id   xx03_slip_numbers.slip_numbers_id%TYPE := NULL;
    ln_slip_num_id       xx03_slip_numbers.slip_numbers_id%TYPE := NULL;
    lv_app_sht_name      xx03_slip_numbers.application_short_name%TYPE := NULL;
    
    ln_slip_num_wrk      NUMBER := NULL;
    
    lb_err_flg           BOOLEAN := FALSE;
    user_exp             EXCEPTION;
BEGIN

--
    BEGIN
        -- ORG_ID 取得
        SELECT haou_ou.organization_id
        INTO   ln_org_id
        FROM hr_all_organization_units haou_bg
            ,hr_all_organization_units haou_ou
        WHERE haou_bg.type = 'BG'
        AND   haou_bg.NAME = 'ITOE-BG'
        AND   haou_ou.BUSINESS_GROUP_ID = haou_bg.ORGANIZATION_ID
        AND   haou_ou.name = 'SALES-OU';
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
         lb_err_flg := TRUE;
         DBMS_OUTPUT.PUT_LINE('★★ ORG_ID 取得失敗 ★★');
    END;
    
    IF lb_err_flg = TRUE THEN
        RAISE user_exp;
    END IF;

--

    BEGIN
        -- slip_numbers_id のMAX 取得
        SELECT max(slip_numbers_id)
        INTO   ln_max_slip_num_id
        FROM xx03_slip_numbers;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
         lb_err_flg := TRUE;
         DBMS_OUTPUT.PUT_LINE('★★ slip_numbers_id のMAX 取得失敗 ★★');
    END;
    
    IF lb_err_flg = TRUE THEN
        RAISE user_exp;
    END IF;
--

    --MAX + 1
    ln_slip_num_id :=  ln_max_slip_num_id + 1;

    -- INSERT
    FOR i IN 1..3 LOOP
    
        -- GL
        IF i = 1 THEN
            ln_slip_num_wrk := 5;
            lv_app_sht_name := 'SQLGL';
        -- AP
        ELSIF i = 2 THEN
            ln_slip_num_wrk := 6;
            lv_app_sht_name := 'SQLAP';
        -- AR
        ELSIF i = 3 THEN
            ln_slip_num_wrk := 8;
            lv_app_sht_name := 'AR';
        END IF;
--
        --仮
        INSERT INTO xx03_slip_numbers(            
                     slip_numbers_id
                    ,application_short_name
                    ,num_type
                    ,temporary_code
                    ,slip_number
                    ,org_id
                    ,created_by
                    ,creation_date
                    ,last_updated_by
                    ,last_update_date
                    ,last_update_login
                ) VALUES (    
                     ln_slip_num_id
                    ,lv_app_sht_name
                    ,0
                    ,'TMP'
                    ,ln_slip_num_wrk * 100000
                    ,ln_org_id
                    ,-1
                    ,SYSDATE
                    ,-1
                    ,SYSDATE
                    ,-1
                    ) ;    
        

        --本
        INSERT INTO xx03_slip_numbers(            
                     slip_numbers_id
                    ,application_short_name
                    ,num_type
                    ,temporary_code
                    ,slip_number
                    ,org_id
                    ,created_by
                    ,creation_date
                    ,last_updated_by
                    ,last_update_date
                    ,last_update_login
                ) VALUES (    
                     ln_slip_num_id + 1
                    ,lv_app_sht_name
                    ,1
                    ,NULL
                    ,ln_slip_num_wrk * 100000000
                    ,ln_org_id
                    ,-1
                    ,SYSDATE
                    ,-1
                    ,SYSDATE
                    ,-1
                    ) ;
                    
        -- インクリメント
        ln_slip_num_id  := ln_slip_num_id + 2;

                    
    END LOOP;
    

EXCEPTION
    WHEN user_exp THEN
        NULL;
    
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- ***********************************
-- 実行後テーブル情報
-- ***********************************
PROMPT ##### xx03_slip_numbers INSERTED Info #####>>>
SELECT *
FROM   xx03_slip_numbers;

