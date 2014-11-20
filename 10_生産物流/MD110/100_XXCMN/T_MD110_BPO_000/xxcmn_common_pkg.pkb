CREATE OR REPLACE PACKAGE BODY xxcmn_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.3
 *
 * Program List
 *  --------------------        ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------        ---- ----- --------------------------------------------------
 *  get_msg                       F   VAR   Message�擾
 *  get_user_name                 F   VAR   �S���Җ��擾
 *  get_user_dept                 F   VAR   �S���������擾
 *  get_tbl_lock                  F   BOL   �e�[�u�����b�N�֐�
 *  del_all_data                  F   BOL   �e�[�u���f�[�^�ꊇ�폜�֐�
 *  get_opminv_close_period       F   VAR   OPM�݌ɉ�v����CLOSE�N���擾�֐�
 *  get_category_desc             F   VAR   �J�e�S���擾�֐�
 *  get_sagara_factory_info       P         �ɓ������ǍH����擾�v���V�[�W��
 *  get_calender_cd               F   VAR   �J�����_�R�[�h�擾�֐�
 *  check_oprtn_day               F   NUM   �ғ����`�F�b�N�֐�
 *  get_seq_no                    P         �̔Ԋ֐�
 *  get_dept_info                 P         �������擾�v���V�[�W��
 *  get_term_of_payment           F   VAR   �x�����������擾�֐�
 *  check_param_date_yyyymm       F   NUM   �p�����[�^�`�F�b�N�F���t�`���iYYYYMM�j
 *  check_param_date_yyyymmdd     F   NUM   �p�����[�^�`�F�b�N�F���t�`���iYYYYMMDD HH24:MI:SS�j
 *  put_api_log                   P   �Ȃ�  �W��API���O�o��API
 *  get_outbound_info             P   �Ȃ�  �A�E�g�o�E���h�������擾�֐�
 *  upd_outbound_info             P   �Ȃ�  �t�@�C���o�͏��X�V�֐�
 *  wf_start                      P   �Ȃ�  ���[�N�t���[�N���֐�
 *  get_can_enc_total_qty         F   NUM   �������\���Z�oAPI
 *  get_can_enc_in_time_qty       F   NUM   �L�����x�[�X�����\���Z�oAPI
 *  get_stock_qty                 F   NUM   �莝�݌ɐ��ʎZ�oAPI
 *  get_can_enc_qty               F   NUM   �����\���Z�oAPI
 *  rcv_ship_conv_qty             F   NUM   ���o�Ɋ��Z�֐�(���Y�o�b�`�p)
 *  get_user_dept_code            F   VAR   �S������CD�擾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/07   1.0   marushita       �V�K�쐬
 *  2008/05/07   1.1   marushita       WF�N���֐���WF�N�����p�����[�^��WF�I�[�i�[��ǉ�
 *  2008/09/18   1.2   Oracle �R�� ��_T_S_453�Ή�(WF�t�@�C���R�s�[)
 *  2008/09/30   1.3   Yuko Kawano      OPM�݌ɉ�v����CLOSE�N���擾�֐� T_S_500�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  resource_busy_expt           EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg'; -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : get_msg
   * Description      :
   ***********************************************************************************/
  FUNCTION get_msg(
    iv_application   IN VARCHAR2,
    iv_name          IN VARCHAR2,
    iv_token_name1   IN VARCHAR2 DEFAULT NULL,
    iv_token_value1  IN VARCHAR2 DEFAULT NULL,
    iv_token_name2   IN VARCHAR2 DEFAULT NULL,
    iv_token_value2  IN VARCHAR2 DEFAULT NULL,
    iv_token_name3   IN VARCHAR2 DEFAULT NULL,
    iv_token_value3  IN VARCHAR2 DEFAULT NULL,
    iv_token_name4   IN VARCHAR2 DEFAULT NULL,
    iv_token_value4  IN VARCHAR2 DEFAULT NULL,
    iv_token_name5   IN VARCHAR2 DEFAULT NULL,
    iv_token_value5  IN VARCHAR2 DEFAULT NULL,
    iv_token_name6   IN VARCHAR2 DEFAULT NULL,
    iv_token_value6  IN VARCHAR2 DEFAULT NULL,
    iv_token_name7   IN VARCHAR2 DEFAULT NULL,
    iv_token_value7  IN VARCHAR2 DEFAULT NULL,
    iv_token_name8   IN VARCHAR2 DEFAULT NULL,
    iv_token_value8  IN VARCHAR2 DEFAULT NULL,
    iv_token_name9   IN VARCHAR2 DEFAULT NULL,
    iv_token_value9  IN VARCHAR2 DEFAULT NULL,
    iv_token_name10  IN VARCHAR2 DEFAULT NULL,
    iv_token_value10 IN VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_msg'; -- �v���O������
--
    -- *** ���[�J���ϐ� ***
    lv_token_name          VARCHAR2(1000);
    lv_token_value         VARCHAR2(2000);
    ln_cnt                 NUMBER;
--
  BEGIN
--
    -- �X�^�b�N�Ƀ��b�Z�[�W���Z�b�g
    FND_MESSAGE.SET_NAME(
      iv_application,
      iv_name);
--
    -- �X�^�b�N�Ƀg�[�N�����Z�b�g
    IF (iv_token_name1 IS NOT NULL) THEN
      -- �J�E���^������
      ln_cnt := 0;
--
      <<token_set>>
      LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- �g�[�N���̒l��2000�o�C�g�𒴂���ꍇ�A
        -- 2000�o�C�g�s������؂�̂Ă�悤�C��
        IF (ln_cnt = 1) THEN
          lv_token_name := iv_token_name1;
          lv_token_value := SUBSTRB(iv_token_value1,1,2000);
        ELSIF (ln_cnt = 2) THEN
          lv_token_name := iv_token_name2;
          lv_token_value := SUBSTRB(iv_token_value2,1,2000);
        ELSIF (ln_cnt = 3) THEN
          lv_token_name := iv_token_name3;
          lv_token_value := SUBSTRB(iv_token_value3,1,2000);
        ELSIF (ln_cnt = 4) THEN
          lv_token_name := iv_token_name4;
          lv_token_value := SUBSTRB(iv_token_value4,1,2000);
        ELSIF (ln_cnt = 5) THEN
          lv_token_name := iv_token_name5;
          lv_token_value := SUBSTRB(iv_token_value5,1,2000);
        ELSIF (ln_cnt = 6) THEN
          lv_token_name := iv_token_name6;
          lv_token_value := SUBSTRB(iv_token_value6,1,2000);
        ELSIF (ln_cnt = 7) THEN
          lv_token_name := iv_token_name7;
          lv_token_value := SUBSTRB(iv_token_value7,1,2000);
        ELSIF (ln_cnt = 8) THEN
          lv_token_name := iv_token_name8;
          lv_token_value := SUBSTRB(iv_token_value8,1,2000);
        ELSIF (ln_cnt = 9) THEN
          lv_token_name := iv_token_name9;
          lv_token_value := SUBSTRB(iv_token_value9,1,2000);
        ELSIF (ln_cnt = 10) THEN
          lv_token_name := iv_token_name10;
          lv_token_value := SUBSTRB(iv_token_value10,1,2000);
        END IF;
--
        EXIT WHEN (lv_token_name IS NULL)
               OR (ln_cnt > 10);
--
        FND_MESSAGE.SET_TOKEN(
          lv_token_name,
          lv_token_value,
          FALSE);
--
      END LOOP token_set;
--
    END IF;
    -- �X�^�b�N�̓��e���擾
    RETURN FND_MESSAGE.GET;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_msg;
--
  /**********************************************************************************
   * Function Name    : get_user_name
   * Description      : �S���Җ��擾
   ***********************************************************************************/
  FUNCTION get_user_name
    (
      in_user_id  IN FND_USER.USER_ID%TYPE    -- ���O�C�����[�U�[ID
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_name' ;  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_user_name    VARCHAR2(100) ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �l���̃e�[�u�����A�����������擾����B
    BEGIN
      SELECT papf.per_information18 || ' ' || papf.per_information19
      INTO   lv_user_name
      FROM per_all_people_f  papf
          ,fnd_user          fu
      WHERE TRUNC(SYSDATE) 
        BETWEEN papf.effective_start_date
        AND     papf.effective_end_date
      AND   fu.employee_id  = papf.person_id
      AND   fu.user_id      = in_user_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_name := NULL ;
    END ;
--
    RETURN lv_user_name ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_user_name ;
--
  /**********************************************************************************
   * Function Name    : get_user_dept
   * Description      : �S���������擾
   ***********************************************************************************/
  FUNCTION get_user_dept
    (
      in_user_id  IN FND_USER.USER_ID%TYPE    -- ���O�C�����[�U�[ID
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_dept' ;  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_user_dept_name   VARCHAR2(100) ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- ���Ə��e�[�u�����A���Ə������擾����B
    BEGIN
      SELECT xla.location_short_name
      INTO   lv_user_dept_name
      FROM xxcmn_locations_all    xla
          ,per_all_assignments_f  paaf
          ,fnd_user               fu
      WHERE TRUNC(SYSDATE)    BETWEEN xla.start_date_active     AND xla.end_date_active
      AND   paaf.location_id  = xla.location_id
      AND   paaf.primary_flag = 'Y'
      AND   TRUNC(SYSDATE)    BETWEEN paaf.effective_start_date AND paaf.effective_end_date
      AND   fu.employee_id    = paaf.person_id
      AND   fu.user_id        = in_user_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_dept_name := NULL ;
    END ;
--
    RETURN lv_user_dept_name ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_user_dept ;
--
  /**********************************************************************************
   * Function Name    : get_tbl_lock
   * Description      : �e�[�u�����b�N�֐�
   ***********************************************************************************/
  FUNCTION get_tbl_lock(
    iv_schema_name IN VARCHAR2,         -- �X�L�[�}��
    iv_table_name  IN VARCHAR2)         -- �e�[�u����
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tbl_lock'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    BEGIN
--
      EXECUTE IMMEDIATE
        'LOCK TABLE ' || iv_schema_name || '.' || iv_table_name ||
        ' IN EXCLUSIVE MODE NOWAIT';
--
      RETURN TRUE;
--
    EXCEPTION
--
      WHEN resource_busy_expt THEN
        RETURN FALSE;
--
    END;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_tbl_lock;
--
  /**********************************************************************************
   * Function Name    : del_all_data
   * Description      : �e�[�u���f�[�^�ꊇ�폜�֐�
   ***********************************************************************************/
  FUNCTION del_all_data(
    iv_schema_name IN VARCHAR2,         -- �X�L�[�}��
    iv_table_name  IN VARCHAR2)         -- �e�[�u����
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_all_data'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    BEGIN
--
      EXECUTE IMMEDIATE
        'TRUNCATE TABLE ' || iv_schema_name || '.' || iv_table_name;
--
      RETURN TRUE;
--
    EXCEPTION
--
      WHEN OTHERS THEN
        RETURN FALSE;
--
    END;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END del_all_data;
--
  /**********************************************************************************
   * Function Name    : get_opminv_close_period
   * Description      : OPM�݌ɉ�v����CLOSE�N���擾�֐�
   ***********************************************************************************/
  FUNCTION get_opminv_close_period 
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_opminv_close_period'; --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prf_min_date_name CONSTANT VARCHAR2(15)  := 'MIN���t';
    -- *** ���[�J���ϐ� ***
    lv_errmsg         VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_return_date    VARCHAR2(10);   -- �ԋp�N��
    lv_min_date       VARCHAR2(10);   -- MIN���t��YYYYMM
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    -- MIN���t�v���t�@�C���擾�G���[
    profile_expt             EXCEPTION;
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- �ŏ����t��YYYMM���擾(�v���t�@�C��)
    lv_min_date := SUBSTRB(REPLACE(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),'/'), 1, 6) ;
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10002',
                                            'NG_PROFILE', cv_prf_min_date_name);
      RAISE profile_expt ;
    END IF ;
--
    -- OPM�݌ɉ�v���ԂōŐV��CLOSE���t���擾
--2008/09/26 Y.Kawano Mod Start
--    SELECT 
--      NVL(TO_CHAR(FND_DATE.STRING_TO_DATE(MAX(oap.period_name), 'MON-RR'), 'YYYYMM'), lv_min_date)
--    INTO   lv_return_date
--    FROM   org_acct_periods       oap,
--           ic_whse_mst            iwm
--    WHERE  iwm.whse_code        = FND_PROFILE.VALUE('XXCMN_COST_PRICE_WHSE_CODE')
--    AND    oap.organization_id  = iwm.mtl_organization_id
--    AND    oap.open_flag        = 'N';
    --
    SELECT 
      NVL(TO_CHAR(MAX(icd.period_end_date), 'YYYYMM'), lv_min_date)
    INTO  lv_return_date
    FROM  ic_cldr_dtl            icd
         ,ic_whse_sts            iws
    WHERE iws.whse_code        = FND_PROFILE.VALUE('XXCMN_COST_PRICE_WHSE_CODE')
    AND   icd.period_id        = iws.period_id
    AND   iws.close_whse_ind  <> 1
    ;
--2008/09/26 Y.Kawano Mod End
--
    RETURN lv_return_date;
--
  EXCEPTION
    WHEN profile_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_opminv_close_period;
--
  /**********************************************************************************
   * Function Name    : get_category_desc
   * Description      : �J�e�S���擾�֐�
   ***********************************************************************************/
  FUNCTION get_category_desc(
    in_item_no      IN  VARCHAR2,     -- �i��
    iv_category_set IN  VARCHAR2)     -- �J�e�S���Z�b�g�R�[�h
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_category_desc'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_description  VARCHAR2(240) ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    BEGIN
--
      -- �i�ڃJ�e�S���}�X�^���{��e�[�u�����A�J�e�S���E�v���擾����B
      SELECT  xcv.description
      INTO    lv_description
      FROM    xxcmn_categories_v    xcv
              ,gmi_item_categories  gic
              ,ic_item_mst_b        iimb
      WHERE   xcv.category_set_name    = iv_category_set
      AND     iimb.item_no             = in_item_no
      AND     iimb.item_id             = gic.item_id
      AND     xcv.category_id          = gic.category_id
      AND     xcv.category_set_id      = gic.category_set_id
      AND     ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_description := NULL;
--
    END;
--
    RETURN lv_description;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_category_desc;
--
  /**********************************************************************************
   * Procedure Name   : get_sagara_factory_info
   * Description      : �ɓ������ǍH����擾�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE get_sagara_factory_info(
    ov_postal_code OUT NOCOPY VARCHAR2,     -- �X�֔ԍ�
    ov_address     OUT NOCOPY VARCHAR2,     -- �Z��
    ov_tel_num     OUT NOCOPY VARCHAR2,     -- �d�b�ԍ�
    ov_fax_num     OUT NOCOPY VARCHAR2,     -- FAX�ԍ�
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sagara_factory_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    SELECT xla.zip                        -- �X�֔ԍ�
           ,xla.address_line1             -- �Z��
           ,xla.phone                     -- �d�b�ԍ�
           ,xla.fax                       -- FAX�ԍ�
    INTO   ov_postal_code
           ,ov_address
           ,ov_tel_num
           ,ov_fax_num
    FROM   hr_locations_all      hla    -- ���Ə��}�X�^
           ,xxcmn_locations_all  xla    -- ���Ə��A�h�I���}�X�^
    WHERE  hla.location_code = FND_PROFILE.VALUE('XXCMN_SAGARA_F_CODE')-- �ɓ������ǍH�ꎖ�Ə��R�[�h
    AND    hla.location_id   = xla.location_id
    AND    TRUNC(SYSDATE) BETWEEN xla.start_date_active AND xla.end_date_active
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10036');
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sagara_factory_info;
--
  /**********************************************************************************
   * Function Name    : get_calender_cd
   * Description      : �J�����_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_calender_cd(
    iv_whse_code      IN  VARCHAR2 DEFAULT NULL,  -- �ۊǑq�ɃR�[�h
    in_party_site_no  IN  VARCHAR2 DEFAULT NULL,  -- �p�[�e�B�T�C�g�ԍ�
    iv_leaf_drink     IN  VARCHAR2)               -- ���[�t�h�����N�敪
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_calender_cd'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_calender_code        VARCHAR2(150);
    lv_basic_calender_code  VARCHAR2(150);
    -- *** ���[�J���萔 ***
    cn_cal_cd_len CONSTANT NUMBER(15,0)  := 150; -- �J�����_�R�[�h��
    cv_leaf       CONSTANT VARCHAR2(1)   := '1'; -- ���[�t
    cv_drink      CONSTANT VARCHAR2(1)   := '2'; -- �h�����N
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- �p�����[�^�`�F�b�N����ъ�J�����_�̎擾
    IF (    (iv_whse_code IS NOT NULL) 
        AND (in_party_site_no IS NULL)
        AND (iv_leaf_drink = cv_leaf)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_LEAF_WHSE_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NOT NULL)
        AND (in_party_site_no IS NULL)
        AND (iv_leaf_drink = cv_drink)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_DRNK_WHSE_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NULL)
        AND (in_party_site_no IS NOT NULL)
        AND (iv_leaf_drink = cv_leaf)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_LEAF_DELIVER_TO_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSIF ((iv_whse_code IS NULL) 
        AND (in_party_site_no IS NOT NULL)
        AND (iv_leaf_drink = cv_drink)) THEN
      lv_basic_calender_code := SUBSTRB(FND_PROFILE.VALUE('XXCMN_DRNK_DELIVER_TO_STD_CAL'),
                                        1, cn_cal_cd_len);
--
    ELSE
      -- ���̑��̏ꍇ��NULL��Ԃ�
      RETURN NULL;
    END IF;
--
    IF (iv_whse_code IS NOT NULL) THEN
    -- �ۊǑq�ɃR�[�h���w�肳�ꂽ�ꍇ
      BEGIN
        SELECT  CASE
                  -- �p�����[�^'���[�t�h�����N�敪'��'���[�t'�̏ꍇ
                  WHEN (iv_leaf_drink = cv_leaf) THEN
                    SUBSTRB(xilv.leaf_calender, 1, cn_cal_cd_len)
                  -- �p�����[�^'���[�t�h�����N�敪'��'�h�����N'�̏ꍇ
                  ELSE
                    SUBSTRB(xilv.drink_calender, 1, cn_cal_cd_len)
                END
        INTO    lv_calender_code
        FROM    xxcmn_item_locations_v xilv
        WHERE   xilv.segment1 = iv_whse_code
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_calender_code := lv_basic_calender_code;
      END;
    ELSIF (in_party_site_no IS NOT NULL) THEN
    -- �p�[�e�B�T�C�g�ԍ����w�肳�ꂽ�ꍇ
      BEGIN
        SELECT  CASE
                  -- �p�����[�^'���[�t�h�����N�敪'��'���[�t'�̏ꍇ
                  WHEN (iv_leaf_drink = cv_leaf) THEN
                    SUBSTRB(xpsv.leaf_calender, 1, cn_cal_cd_len)
                  -- �p�����[�^'���[�t�h�����N�敪'��'�h�����N'�̏ꍇ
                  ELSE
                    SUBSTRB(xpsv.drink_calender, 1, cn_cal_cd_len)
                END
        INTO    lv_calender_code
        FROM    xxcmn_party_sites_v xpsv
        WHERE   xpsv.ship_to_no = in_party_site_no
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_calender_code := lv_basic_calender_code;
      END;
    END IF;
--
    RETURN NVL(lv_calender_code, lv_basic_calender_code);
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_calender_cd;
--
  /**********************************************************************************
   * Function Name    : check_oprtn_day
   * Description      : �ғ����`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION check_oprtn_day(
    id_date         IN  DATE,      -- �`�F�b�N�Ώۓ��t
    iv_calender_cd  IN  VARCHAR2)  -- �J�����_�[�R�[�h
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_oprtn_day'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_active     NUMBER(5,0) := 0;
    -- *** ���[�J���ϐ� ***
    ln_ret_num    NUMBER(1); -- �߂�l
    ln_cnt        NUMBER(1); -- �擾����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    ln_ret_num := gn_ret_nomal;
--
    SELECT  COUNT(1)
    INTO    ln_cnt
    FROM    mr_shcl_hdr msh,
            mr_shcl_dtl msd
    WHERE   msh.calendar_no   = iv_calender_cd
    AND     msh.calendar_id   = msd.calendar_id
    AND     msd.calendar_date = TRUNC(id_date)
    AND     msd.delete_mark   = cn_active
    AND     ROWNUM = 1;
--
    IF (ln_cnt = 0) THEN
      ln_ret_num := gn_ret_error;
    END IF;
--
    RETURN ln_ret_num;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_oprtn_day;
--
  /**********************************************************************************
   * Procedure Name   : get_seq_no
   * Description      : �`�[�ԍ��ȂǂŎg�p����ԍ����̔Ԃ��܂�
   ***********************************************************************************/
  PROCEDURE get_seq_no(
    iv_seq_class  IN  VARCHAR2,            --   �̔Ԃ���ԍ���\���敪
    ov_seq_no     OUT NOCOPY VARCHAR2,     --   �̔Ԃ����Œ蒷12���̔ԍ�
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcmn_common_pkg.get_seq_no'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_slip_no             CONSTANT VARCHAR2(100) := '�`�[�ԍ�';
--
    -- *** ���[�J���ϐ� ***
    lv_seq_admit  VARCHAR2(1);
    lv_seq_yyyymm VARCHAR2(6);
    ln_no         NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
  seq_admin_exp               EXCEPTION;     -- �̔ԉێ擾�G���[
  seq_yyyymm_exp              EXCEPTION;     -- �̔ԗp���ݔN���擾�G���[
  get_set_seq_exp             EXCEPTION;     -- �V�[�P���X�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lv_seq_admit := SUBSTR(FND_PROFILE.VALUE('XXCMN_SEQ_ADMIT'),1,1); -- �v���t�@�C���擾
--
    -- �v���t�@�C����'Y'�łȂ����ANULL�̏ꍇ�̓G���[
    IF ((lv_seq_admit != 'Y') OR (lv_seq_admit IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10031');
      lv_errbuf := lv_errmsg;
      RAISE seq_admin_exp;
    END IF;
--
    lv_seq_yyyymm := SUBSTR(FND_PROFILE.VALUE('XXCMN_SEQ_YYYYMM'),1,6); -- �v���t�@�C���擾
--
    IF (lv_seq_yyyymm IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10032');
      lv_errbuf := lv_errmsg;
      RAISE seq_yyyymm_exp;
    END IF;
--
    BEGIN
      -- �̔Ԃ�1�̃V�[�P���X�ōs���ꍇ
      SELECT xxcmn_slip_no_s1.NEXTVAL INTO ln_no FROM dual;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10029',
                                              'SEQ_NAME',
                                              cv_slip_no);
        lv_errbuf := lv_errmsg;
        RAISE get_set_seq_exp;
    END;
--
    ov_seq_no := SUBSTRB(lv_seq_yyyymm, -4) || TO_CHAR(ln_no, 'FM00000000');
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN seq_admin_exp THEN                           --*** �̔ԉێ擾��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN seq_yyyymm_exp THEN                           --*** �̔ԗp���ݔN���擾��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN get_set_seq_exp THEN                            --*** �V�[�P���X�擾��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_seq_no;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_info
   * Description      : �������擾�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE get_dept_info(
    iv_dept_cd          IN  VARCHAR2,          -- �����R�[�h(���Ə�CD)
    id_appl_date        IN  DATE DEFAULT NULL, -- ���
    ov_postal_code      OUT NOCOPY VARCHAR2,          -- �X�֔ԍ�
    ov_address          OUT NOCOPY VARCHAR2,          -- �Z��
    ov_tel_num          OUT NOCOPY VARCHAR2,          -- �d�b�ԍ�
    ov_fax_num          OUT NOCOPY VARCHAR2,          -- FAX�ԍ�
    ov_dept_formal_name OUT NOCOPY VARCHAR2,          -- ����������
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dept_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_basic_date DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ld_basic_date := NVL(id_appl_date, TRUNC(SYSDATE));
--
    SELECT  xlv.zip,
            xlv.address_line1,
            xlv.phone,
            xlv.fax,
            xlv.location_name
    INTO    ov_postal_code,
            ov_address,
            ov_tel_num,
            ov_fax_num,
            ov_dept_formal_name
    FROM    xxcmn_locations2_v xlv
    WHERE   xlv.location_code =  iv_dept_cd
    AND     ((xlv.inactive_date IS NULL) OR (xlv.inactive_date > ld_basic_date))
    AND     ld_basic_date BETWEEN xlv.start_date_active AND xlv.end_date_active;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10036');
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dept_info;
--
  /**********************************************************************************
   * Function Name    : get_term_of_payment
   * Description      : �x�����������擾�֐�
   ***********************************************************************************/
  FUNCTION get_term_of_payment(
    in_vendor_id   IN NUMBER,
    id_appl_date   IN DATE DEFAULT NULL)
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_term_of_payment'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_effective_date     DATE;
    lv_pay_flag           VARCHAR2(1);
    lv_pay_desc1          VARCHAR2(1000);
    lv_pay_desc2          VARCHAR2(1000);
    lv_pay_desc3          VARCHAR2(1000);
    lv_pay_date_pat       VARCHAR2(50);
    lv_pay_date           VARCHAR2(50);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    invalid_pattern_expt             EXCEPTION;     -- ���t�t�H�[�}�b�g�s���G���[
--
    PRAGMA EXCEPTION_INIT(invalid_pattern_expt, -1821);
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �L������ݒ�
    IF (id_appl_date IS NULL) THEN
      ld_effective_date := TRUNC(SYSDATE);
    ELSE
      ld_effective_date := id_appl_date;
    END IF;
--
    -- �x�����������̎擾�p�^�[�����擾
    lv_pay_flag := SUBSTRB(FND_PROFILE.VALUE('XXCMN_PAY_FLAG'), 1);
--
    IF (lv_pay_flag = '1') THEN
      -- �p�^�[���ɑΉ����������̎擾
      lv_pay_desc1 := FND_PROFILE.VALUE('XXCMN_PAY_DESC1');
      lv_pay_desc2 := FND_PROFILE.VALUE('XXCMN_PAY_DESC2');
      lv_pay_date_pat := FND_PROFILE.VALUE('XXCMN_PAY_DATE_PAT');
--
      -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ�͏I��
      IF (   (lv_pay_desc1 IS NULL)
          OR (lv_pay_desc2 IS NULL)
          OR (lv_pay_date_pat IS NULL)) THEN
        RETURN NULL;
      END IF;
--
      -- �x�������ݒ�����擾
      BEGIN
        SELECT  TO_CHAR(xvv.terms_date, lv_pay_date_pat)
        INTO    lv_pay_date
        FROM    xxcmn_vendors2_v xvv
        WHERE   xvv.vendor_id         = in_vendor_id
        AND     (   (xvv.inactive_date     IS NULL)
                 OR (xvv.inactive_date > ld_effective_date))
        AND     (   (xvv.start_date_active IS NULL) 
                 OR (xvv.start_date_active <= ld_effective_date))
        AND     (   (xvv.end_date_active   IS NULL) 
                 OR (xvv.end_date_active   >= ld_effective_date))
        AND     ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN invalid_pattern_expt THEN
          RETURN NULL;
      END;
--
      IF (lv_pay_date IS NULL) THEN
        RETURN NULL;
      END IF;
--
      -- �������쐬
      RETURN lv_pay_desc1 || lv_pay_date || lv_pay_desc2;
--
    ELSIF (lv_pay_flag = '2') THEN
      -- �������쐬
      lv_pay_desc3 := FND_PROFILE.VALUE('XXCMN_PAY_DESC3');
      RETURN lv_pay_desc3;
--
    ELSE
      -- NULL���܂ߑΏۊO�̃p�^�[���̓G���[�Ƃ���B
      RETURN NULL;
    END IF;
--
    RETURN NULL;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_term_of_payment;
--
  /**********************************************************************************
   * Function Name    : check_param_date_yyyymm
   * Description      : �p�����[�^�`�F�b�N�F���t�`��(YYYYMM)
   ***********************************************************************************/
  FUNCTION check_param_date_yyyymm(
    iv_date_ym      VARCHAR2)
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_date_yyyymm' ; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_temp_date    DATE ;
    ln_ret_num      NUMBER := gn_ret_nomal;
--
  BEGIN
--
    ld_temp_date := FND_DATE.STRING_TO_DATE( iv_date_ym, 'YYYY/MM' ) ;
--
    -- ���t���擾�ł��Ȃ������ꍇ
    IF ld_temp_date IS NULL THEN
      ln_ret_num := gn_ret_error;
--
    -- ���t���擾�ł����ꍇ
    ELSE
      ln_ret_num := gn_ret_nomal;
--
    END IF ;
--
    RETURN ln_ret_num ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_param_date_yyyymm ;
--
  /**********************************************************************************
   * Function Name    : check_param_date_yyyymmdd
   * Description      : �p�����[�^�`�F�b�N�F���t�`��(YYYYMMDD HH24:MI:SS)
   ***********************************************************************************/
  FUNCTION check_param_date_yyyymmdd(
    iv_date_ymd      VARCHAR2)
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_date_yyyymmdd' ; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_temp_date    DATE ;
    ln_ret_num      NUMBER := gn_ret_nomal;
--
  BEGIN
--
    ld_temp_date := FND_DATE.STRING_TO_DATE( iv_date_ymd, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ���t���擾�ł��Ȃ������ꍇ
    IF ld_temp_date IS NULL THEN
      ln_ret_num := gn_ret_error;
--
    -- ���t���擾�ł����ꍇ
    ELSE
      ln_ret_num := gn_ret_nomal;
--
    END IF ;
--
    RETURN ln_ret_num ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END check_param_date_yyyymmdd ;
--
  /**********************************************************************************
   * Procedure Name   : put_api_log
   * Description      : �W��API���O�o��API�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE put_api_log(
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_api_log'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg            VARCHAR2(32000);
    ln_dummy_cnt      NUMBER(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<count_msg_loop>>
    FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
      -- ���b�Z�[�W�擾
      FND_MSG_PUB.GET(
             p_msg_index      => i
            ,p_encoded        => FND_API.G_FALSE
            ,p_data           => lv_msg
            ,p_msg_index_out  => ln_dummy_cnt
      );
      -- ���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
--
    END LOOP count_msg_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_api_log;
--
  /**********************************************************************************
   * Procedure Name   : get_outbound_info
   * Description      : �A�E�g�o�E���h�������擾�֐�
   ***********************************************************************************/
  PROCEDURE get_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    or_outbound_rec     OUT NOCOPY outbound_rec,      -- �t�@�C�����
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_outbound_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_wf_noti        CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION'; -- Workflow�ʒm
    cv_wf_info        CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO'; -- Workflow�ʒm
    cv_prof_min_date  CONSTANT VARCHAR2(100) := 'XXCMN_MIN_DATE';
    cv_prof_min_date_name CONSTANT VARCHAR2(15)  := 'MIN���t';
    cv_xxcmn_outboud_name CONSTANT VARCHAR2(50)  := '�A�E�g�o�E���h';
--
    -- *** ���[�J���ϐ� ***
    ld_min_date               DATE;         -- MIN���t
    lr_outbound_rec           outbound_rec; -- outbound�֘A�f�[�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_min_date_expt                 EXCEPTION;     -- MIN���t�����݂��Ȃ��G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- MIN���t�擾
    ld_min_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE(cv_prof_min_date), 'YYYY/MM/DD');
    IF (ld_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                            'APP-XXCMN-10002',
                                            'NG_PROFILE',
                                            cv_prof_min_date_name);
      RAISE no_min_date_expt;
    END IF;
--
    BEGIN
      -- �ŏI�X�V�����擾
      SELECT xo.file_last_update_date
      INTO   lr_outbound_rec.file_last_update_date
      FROM   xxcmn_outbound xo
      WHERE  xo.wf_ope_div      = iv_wf_ope_div
      AND    xo.wf_class        = iv_wf_class
      AND    xo.wf_notification = iv_wf_notification
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10019',
                                              'TABLE',
                                              cv_xxcmn_outboud_name);
        RAISE resource_busy_expt;
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.file_last_update_date := ld_min_date;
    END;
--
    BEGIN
      -- �ʒm�惆�[�U�[���擾
      SELECT  xlv.attribute1,
              xlv.attribute2,
              xlv.attribute3,
              xlv.attribute4,
              xlv.attribute5,
              xlv.attribute6,
              xlv.attribute7,
              xlv.attribute8,
              xlv.attribute9,
              xlv.attribute10,
              xlv.attribute11,
              xlv.attribute12
      INTO    lr_outbound_rec.wf_class,
              lr_outbound_rec.wf_notification,
              lr_outbound_rec.user_cd01,
              lr_outbound_rec.user_cd02,
              lr_outbound_rec.user_cd03,
              lr_outbound_rec.user_cd04,
              lr_outbound_rec.user_cd05,
              lr_outbound_rec.user_cd06,
              lr_outbound_rec.user_cd07,
              lr_outbound_rec.user_cd08,
              lr_outbound_rec.user_cd09,
              lr_outbound_rec.user_cd10
      FROM    xxcmn_lookup_values_v xlv
      WHERE  xlv.lookup_type  = cv_wf_noti
      AND    xlv.attribute1   = iv_wf_class
      AND    xlv.attribute2   = iv_wf_notification
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.wf_class        := iv_wf_class;
        lr_outbound_rec.wf_notification := iv_wf_notification;
        lr_outbound_rec.user_cd01 := NULL;
        lr_outbound_rec.user_cd02 := NULL;
        lr_outbound_rec.user_cd03 := NULL;
        lr_outbound_rec.user_cd04 := NULL;
        lr_outbound_rec.user_cd05 := NULL;
        lr_outbound_rec.user_cd06 := NULL;
        lr_outbound_rec.user_cd07 := NULL;
        lr_outbound_rec.user_cd08 := NULL;
        lr_outbound_rec.user_cd09 := NULL;
        lr_outbound_rec.user_cd10 := NULL;
    END;
--
    BEGIN
      -- ���[�N�t���[�����擾
      SELECT  xlv.attribute4,
              xlv.attribute5,
              xlv.attribute6,
              xlv.attribute7,
              xlv.attribute8
      INTO    lr_outbound_rec.wf_name,
              lr_outbound_rec.wf_owner,
              lr_outbound_rec.directory,
              lr_outbound_rec.file_name,
              lr_outbound_rec.file_display_name
      FROM    xxcmn_lookup_values_v xlv
      WHERE   xlv.lookup_type   = cv_wf_info
      AND     xlv.attribute1    = iv_wf_ope_div
      AND     xlv.attribute2    = iv_wf_class
      AND     xlv.attribute3    = iv_wf_notification
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lr_outbound_rec.wf_name   := NULL;
        lr_outbound_rec.wf_owner  := NULL;
        lr_outbound_rec.directory := NULL;
        lr_outbound_rec.file_name := NULL;
        lr_outbound_rec.file_display_name := NULL;
    END;
--
    or_outbound_rec := lr_outbound_rec;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN resource_busy_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_min_date_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_outbound_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_outbound_info
   * Description      : �t�@�C���o�͏��X�V�֐�
   ***********************************************************************************/
  PROCEDURE upd_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    id_last_update_date IN  DATE,                     -- �t�@�C���ŏI�X�V��
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_outbound_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt    NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxcmn_outbound  xo
    WHERE  xo.wf_ope_div               = iv_wf_ope_div
    AND    xo.wf_class                 = iv_wf_class
    AND    xo.wf_notification          = iv_wf_notification;
--
    IF (ln_cnt = 0) THEN
      -- ���݂��Ȃ��ꍇ�͓o�^����B
      INSERT INTO xxcmn_outbound(
        wf_ope_div,
        wf_class,
        wf_notification,
        file_last_update_date,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date
      )
      VALUES(
        iv_wf_ope_div,
        iv_wf_class,
        iv_wf_notification,
        id_last_update_date,
        FND_GLOBAL.USER_ID,
        SYSDATE,
        FND_GLOBAL.USER_ID,
        SYSDATE,
        FND_GLOBAL.LOGIN_ID,
        FND_GLOBAL.CONC_REQUEST_ID,
        FND_GLOBAL.PROG_APPL_ID,
        FND_GLOBAL.CONC_PROGRAM_ID,
        SYSDATE
      );
    ELSE
      -- �f�[�^�����݂���ꍇ�͍X�V����
      UPDATE xxcmn_outbound  xo
      SET    xo.file_last_update_date    = id_last_update_date,
             xo.last_updated_by          = FND_GLOBAL.USER_ID,
             xo.last_update_date         = SYSDATE,
             xo.last_update_login        = FND_GLOBAL.LOGIN_ID,
             xo.request_id               = FND_GLOBAL.CONC_REQUEST_ID,
             xo.program_application_id   = FND_GLOBAL.PROG_APPL_ID,
             xo.program_id               = FND_GLOBAL.CONC_PROGRAM_ID,
             xo.program_update_date      = SYSDATE
      WHERE  xo.wf_ope_div               = iv_wf_ope_div
      AND    xo.wf_class                 = iv_wf_class
      AND    xo.wf_notification          = iv_wf_notification;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_outbound_info;
--
  /**********************************************************************************
   * Procedure Name   : wf_start
   * Description      : ���[�N�t���[�N���֐�
   ***********************************************************************************/
  PROCEDURE wf_start(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_start'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_joint_word     CONSTANT VARCHAR2(4)   := '_';
    lv_extend_word    CONSTANT VARCHAR2(4)   := '.csv';
--
    -- *** ���[�J���ϐ� ***
    lv_itemkey VARCHAR2(30);
    lr_outbound_rec           outbound_rec; -- outbound�֘A�f�[�^
--
    lv_file_name   VARCHAR2(300);       --2009/09/18 Add
    ln_len         NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_wf_info_expt                  EXCEPTION;     -- ���[�N�t���[���ݒ�G���[
    wf_exec_expt                     EXCEPTION;     -- ���[�N�t���[���s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- WF�Ɋ֘A��������擾
    get_outbound_info(
      iv_wf_ope_div,
      iv_wf_class,
      iv_wf_notification,
      lr_outbound_rec,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE no_wf_info_expt;
    END IF;
--
--2008/09/18 Add ��
    ln_len := LENGTH(lr_outbound_rec.file_name);
--
    -- �t�@�C�����̉��H(�t�@�C���� - '.CSV'+'_'+'YYYYMMDDHH24MISS'+'.CSV')
    lv_file_name := SUBSTR(lr_outbound_rec.file_name,1,ln_len-4)
                    || lv_joint_word
                    || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
                    || lv_extend_word;
--
    -- �t�@�C���R�s�[
    UTL_FILE.FCOPY(lr_outbound_rec.directory,     -- �R�s�[��_DIR
                   lr_outbound_rec.file_name,     -- �R�s�[��_FILE
                   lr_outbound_rec.directory,     -- �R�s�[��_DIR
                   lv_file_name                   -- �R�s�[��_FILE
                  );
--
    lr_outbound_rec.file_name := lv_file_name;
--2008/09/18 Add ��
--
    --WF�^�C�v�ň�ӂƂȂ�WF�L�[���擾
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WF�v���Z�X���쐬
      WF_ENGINE.CREATEPROCESS(lr_outbound_rec.wf_name, lv_itemkey, lr_outbound_rec.wf_name);
      --WF�I�[�i�[��ݒ�
      WF_ENGINE.SETITEMOWNER(lr_outbound_rec.wf_name, lv_itemkey, lr_outbound_rec.wf_owner);
      --WF������ݒ�
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  lr_outbound_rec.directory|| ',' ||lr_outbound_rec.file_name );
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  lr_outbound_rec.user_cd01);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  lr_outbound_rec.user_cd02);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  lr_outbound_rec.user_cd03);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  lr_outbound_rec.user_cd04);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  lr_outbound_rec.user_cd05);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  lr_outbound_rec.user_cd06);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  lr_outbound_rec.user_cd07);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  lr_outbound_rec.user_cd08);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  lr_outbound_rec.user_cd09);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  lr_outbound_rec.user_cd10);
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  lr_outbound_rec.file_display_name);
      -- 1.1�ǉ�
      WF_ENGINE.SETITEMATTRTEXT(lr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'WF_OWNER',
                                  lr_outbound_rec.wf_owner);
--
      --WF�v���Z�X���N��
      WF_ENGINE.STARTPROCESS(lr_outbound_rec.wf_name, lv_itemkey);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10117');
        RAISE wf_exec_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_wf_info_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
    WHEN wf_exec_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END wf_start;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_total_qty
   * Description      : �������\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_total_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_total_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_total_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty
   * Description      : �L�����x�[�X�����\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_qty NUMBER;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_in_time_qty(in_whse_id,
                                                          in_item_id,
                                                          in_lot_id,
                                                          in_active_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_in_time_qty;
--
  /**********************************************************************************
   * Function Name    : get_stock_qty
   * Description      : �莝�݌ɐ��ʎZ�oAPI
   ***********************************************************************************/
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_stock_qty(in_whse_id, in_item_id, in_lot_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_stock_qty;
--
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty
   * Description      : �����\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER                                     -- �����\��
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_qty NUMBER;
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_qty := 0;
    BEGIN
      ln_qty := xxcmn_common2_pkg.get_can_enc_qty(in_whse_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    RETURN ln_qty;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_qty;
--
  /**********************************************************************************
   * Function Name    : rcv_ship_conv_qty
   * Description      : ���o�Ɋ��Z�֐�(���Y�o�b�`�p)
   ***********************************************************************************/
  FUNCTION rcv_ship_conv_qty(
    iv_conv_type  IN VARCHAR2,          -- �ϊ����@(1:���o�Ɋ��Z�P�ʁ���1�P��,2:���̋t)
    in_item_id    IN NUMBER,            -- OPM�i��ID
    in_qty        IN NUMBER)            -- �ϊ��Ώۂ̐���
    RETURN NUMBER                      -- �ϊ����ʂ̐���
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rcv_ship_conv_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_to_inout   CONSTANT VARCHAR2(1)  := '1'; -- ���o�Ɋ��Z�P�ʂ����1�P�ʂ֕ϊ�
    cv_to_first   CONSTANT VARCHAR2(1)  := '2'; -- ��1�P�ʂ�����o�Ɋ��Z�P�ʂ֕ϊ�
    cv_drink      CONSTANT VARCHAR2(1)  := '2'; -- �h�����N
    -- *** ���[�J���ϐ� ***
    lv_errmsg        VARCHAR2(5000); -- �G���[���b�Z�[�W
    ln_conv_factor     NUMBER; -- ���Z�W��
    ln_converted_num  NUMBER; -- ���Z����
    lt_prod_class_code mtl_categories_b.segment1%TYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    invalid_conv_unit_expt           EXCEPTION;     -- �s���Ȋ��Z�W���G���[
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_converted_num := 0;
--
    -- �i�ڂɂЂ��Â����Z�W�����擾����B
    BEGIN
      SELECT  CASE
                WHEN (ximv.conv_unit IS NULL) THEN 1
                ELSE TO_NUMBER(ximv.num_of_cases)
              END
             ,xicv.prod_class_code 
      INTO    ln_conv_factor
             ,lt_prod_class_code
      FROM    xxcmn_item_mst_v          ximv -- �i�ڏ��VIEW
             ,xxcmn_item_categories4_v  xicv -- �i�ڃJ�e�S�����VIEW4
      WHERE   ximv.item_id = xicv.item_id
      AND     ximv.item_id = in_item_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_conv_factor := NULL;
--
    END;
--
    -- ���i�敪���h�����N�ł͖����ꍇ�͊��Z���s��Ȃ��B
    IF (cv_drink <> lt_prod_class_code) THEN
      ln_converted_num :=  in_qty;
--
    ELSE
      -- ���Z�W�����擾�ł��Ȃ��A0�ȉ��̓G���[
      IF( (ln_conv_factor IS NULL) OR (ln_conv_factor <= 0)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10133','CONV_UNIT', ln_conv_factor);
        RAISE invalid_conv_unit_expt;
      END IF;
--
      IF (iv_conv_type = cv_to_inout) THEN
        ln_converted_num := in_qty * ln_conv_factor;
--
      ELSE
        ln_converted_num := in_qty / ln_conv_factor;
--
      END IF;
--
    END IF;
--
    RETURN ln_converted_num;
--
  EXCEPTION
    WHEN invalid_conv_unit_expt THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END rcv_ship_conv_qty;
--
  /**********************************************************************************
   * Function Name    : get_user_dept_code
   * Description      : �S������CD�擾
   ***********************************************************************************/
  FUNCTION get_user_dept_code
    (
      in_user_id    IN FND_USER.USER_ID%TYPE,  -- ���O�C�����[�U�[ID
      id_appl_date  IN DATE DEFAULT NULL       -- ���
    )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_dept_code' ;  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_user_dept_cd   VARCHAR2(100) ;
    ld_appl_date      DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    -- �����NULL�̏ꍇ��SYSDATE��ݒ�
    IF (id_appl_date IS NULL) THEN
      ld_appl_date := TRUNC(SYSDATE);
    ELSE
      ld_appl_date := TRUNC(id_appl_date);
    END IF;
--
    -- ���[�U�[�ɂЂ��Â��S�������R�[�h���擾����B
    BEGIN
      SELECT xlv.location_code
      INTO   lv_user_dept_cd
      FROM per_all_assignments_f  paaf
          ,fnd_user               fu
          ,xxcmn_locations2_v     xlv
      WHERE fu.user_id        = in_user_id
      AND   fu.employee_id    = paaf.person_id
      AND   paaf.primary_flag = 'Y'
      AND   ld_appl_date    BETWEEN paaf.effective_start_date AND paaf.effective_end_date
      AND   paaf.location_id  = xlv.location_id
      AND   ld_appl_date    BETWEEN xlv.start_date_active     AND xlv.end_date_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_user_dept_cd := NULL ;
    END ;
--
    RETURN lv_user_dept_cd ;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_user_dept_code ;
--
END xxcmn_common_pkg;
/
