CREATE OR REPLACE PACKAGE BODY APPS.xxcso_020001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_020001j_pkg(BODY)
 * Description      : �t���x���_�[SP�ꌈ
 * MD.050/070       : 
 * Version          : 1.19
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  initialize_transaction    P    -     �g�����U�N�V��������������
 *  process_request           P    -     �ʒm���[�N�t���[�N������
 *  process_lock              P    -     �g�����U�N�V�������b�N����
 *  get_inst_info_parameter   F    V     �ݒu���񔻒�
 *  get_cntr_info_parameter   F    V     �_����񔻒�
 *  get_bm1_info_parameter    F    V     BM1��񔻒�
 *  get_bm2_info_parameter    F    V     BM2��񔻒�
 *  get_bm3_info_parameter    F    V     BM3��񔻒�
 *  calculate_sc_line         P    -     �����ʏ����v�Z�i���׍s���Ɓj
 *  calculate_cc_line         P    -     �ꗥ�����E�e��ʏ����v�Z�i���׍s���Ɓj
 *  get_gross_profit_rate     F    V     �e�����擾
 *  calculate_est_year_profit P    -     �T�Z�N�ԑ��v�v�Z
 *  get_appr_auth_level_num_1 F    N     ���F�������x���ԍ��P�擾
 *  get_appr_auth_level_num_2 F    N     ���F�������x���ԍ��Q�擾
 *  get_appr_auth_level_num_3 F    N     ���F�������x���ԍ��R�擾
 *  get_appr_auth_level_num_4 F    N     ���F�������x���ԍ��S�擾
 *  get_appr_auth_level_num_5 F    N     ���F�������x���ԍ��T�擾
 *  get_appr_auth_level_num_0 F    N     ���F�������x���ԍ��i�f�t�H���g�j�擾
 *  conv_number_separate      P    -     ���l�Z�p���[�g�ϊ�
 *  conv_line_number_separate P    -     ���l�Z�p���[�g�ϊ��i���ׁj
 *  chk_double_byte           F    V     �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_single_byte_kana      F    V     ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_account_many          P    -     �A�J�E���g�����`�F�b�N
 *  chk_cust_site_uses        P    -     �ڋq�g�p�ړI�`�F�b�N
 *  chk_validate_db           P    -     �c�a�X�V����`�F�b�N
 *  get_contract_end_period   F    V     �_��I�����Ԏ擾
 *  get_required_check_flag   F    N     �H���A�ݒu�����݊��ԕK�{�t���O�擾
 *  chk_vendor_inbalid        P    -     �d���斳�����`�F�b�N
 *  
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/23    1.0   H.Ogawa          �V�K�쐬
 *  2009/03/23    1.1   N.Yanagitaira    [��QT1_0163]���F���_���update�����C��
 *  2009/04/06    1.2   N.Yanagitaira    [��QT1_0316]�񑗐惌�R�[�h�X�V�����C��
 *  2009/04/09    1.3   K.Satomura       [��QT1_0424]���F�������E���ٓ��ݒ�l�C��
 *  2009/04/17    1.4   N.Yanagitaira    [��QT1_0536]�ʒm���[�N�t���[���M���ݒ�l�C��
 *  2009/04/27    1.5   N.Yanagitaira    [��QT1_0708]���͍��ڃ`�F�b�N��������C��
 *                                                    chk_double_byte
 *                                                    chk_single_byte_kana
 *  2009/05/01    1.6   T.Mori           [��QT1_0897]�X�L�[�}���ݒ�
 *  2009/05/07    1.7   N.Yanagitaira    [��QT1_0200]VD���[�X���A��p���v�Z�o���@�C��
 *  2009/06/05    1.8   N.Yanagitaira    [��QT1_1307]chk_single_byte_kana�C��
 *  2009/07/16    1.9   D.Abe            [SCS��Q0000385]SP�ꌈ���۔F���̃t���[�ύX
 *  2009/10/26    1.10  K.Satomura       [E_T4_00075]���v����_�̌v�Z���@�C��
 *  2009/11/29    1.11  D.Abe            [E_�{�ғ�_00106]�A�J�E���g��������
 *  2010/01/12    1.12  D.Abe            [E_�{�ғ�_00823]�ڋq�}�X�^�̐������`�F�b�N�Ή�
 *  2010/01/15    1.13  D.Abe            [E_�{�ғ�_00950]�c�a�X�V����`�F�b�N�Ή�
 *  2010/03/01    1.14  D.Abe            [E_�{�ғ�_01678]�����x���Ή�
 *  2014/12/15    1.15  K.Kiriu          [E_�{�ғ�_12565]SP�E�_�񏑉�ʉ��C�Ή�
 *  2018/05/16    1.16  Y.Shoji          [E_�{�ғ�_14989]�r�o���ڒǉ�
 *  2020/10/28    1.17  Y.Sasaki         [E_�{�ғ�_16293]SP�E�_�񏑉�ʂ���̎d����R�[�h�̑I���ɂ���
 *  2020/11/12    1.18  Y.Sasaki         [E_�{�ғ�_15904]��O�e �艿���Z���Z�o�ύX
 *  2021/04/16    1.19  T.Nishikawa      [E_�{�ғ�_17052]�艿���Z���Z�o���@������
*****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_020001j_pkg';   -- �p�b�P�[�W��
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  nowait_except       EXCEPTION;
  PRAGMA EXCEPTION_INIT(nowait_except, -54);
--
  /**********************************************************************************
   * Function Name    : initialize_transaction
   * Description      : �g�����U�N�V��������������
   ***********************************************************************************/
  PROCEDURE initialize_transaction(
    iv_sp_decision_header_id    IN  VARCHAR2
   ,iv_app_base_code            IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'initialize_transaction';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    SELECT  COUNT('x')
    INTO    ln_count
    FROM    xxcso_tmp_sp_dec_request  xtsdr
    ;
--
    IF ( ln_count = 0 ) THEN
--
      INSERT INTO    xxcso_tmp_sp_dec_request(
                       sp_decision_header_id
                      ,app_base_code
                      ,created_by
                      ,creation_date
                      ,last_updated_by
                      ,last_update_date
                      ,last_update_login
                     )
             VALUES  (
                       TO_NUMBER(iv_sp_decision_header_id)
                      ,iv_app_base_code
                      ,fnd_global.user_id
                      ,SYSDATE
                      ,fnd_global.user_id
                      ,SYSDATE
                      ,fnd_global.login_id
                     )
      ;
--
    ELSE
--
      UPDATE  xxcso_tmp_sp_dec_request
      SET     sp_decision_header_id = TO_NUMBER(iv_sp_decision_header_id)
             ,app_base_code         = iv_app_base_code
             ,created_by            = fnd_global.user_id
             ,creation_date         = SYSDATE
             ,last_updated_by       = fnd_global.user_id
             ,last_update_date      = SYSDATE
             ,last_update_login     = fnd_global.login_id
      ;
--
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END initialize_transaction;
--
  /**********************************************************************************
   * Function Name    : process_request
   * Description      : �ʒm���[�N�t���[�N������
   ***********************************************************************************/
  PROCEDURE process_request(
    ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_request';
    cv_operation_submit          CONSTANT VARCHAR2(30)    := 'SUBMIT';
    cv_operation_confirm         CONSTANT VARCHAR2(30)    := 'CONFIRM';
    cv_operation_return          CONSTANT VARCHAR2(30)    := 'RETURN';
    cv_operation_approve         CONSTANT VARCHAR2(30)    := 'APPROVE';
    cv_operation_reject          CONSTANT VARCHAR2(30)    := 'REJECT';
    cv_approve_init              CONSTANT VARCHAR2(1)     := '*';
    cv_approval_state_none       CONSTANT VARCHAR2(1)     := '0';
    cv_approval_state_during     CONSTANT VARCHAR2(1)     := '1';
    cv_approval_state_end        CONSTANT VARCHAR2(1)     := '2';
    cv_content_approve           CONSTANT VARCHAR2(1)     := '1';
    cv_content_reject            CONSTANT VARCHAR2(1)     := '2';
    cv_content_confirm           CONSTANT VARCHAR2(1)     := '3';
    cv_content_return            CONSTANT VARCHAR2(1)     := '4';
    cv_status_request            CONSTANT VARCHAR2(1)     := '2';
    cv_status_enabled            CONSTANT VARCHAR2(1)     := '3';
    cv_status_reject             CONSTANT VARCHAR2(1)     := '4';
    cv_request_approve           CONSTANT VARCHAR2(1)     := '1';
    cv_notify_reject             CONSTANT VARCHAR2(1)     := '3';
    cv_notify_return             CONSTANT VARCHAR2(1)     := '4';
    cv_notify_approve_end        CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_operation_mode            xxcso_tmp_sp_dec_request.operation_mode%TYPE;
    ln_sp_decision_header_id     xxcso_tmp_sp_dec_request.sp_decision_header_id%TYPE;
    lv_application_code          xxcso_sp_decision_headers.application_code%TYPE;
    lv_status                    xxcso_sp_decision_headers.status%TYPE;
    lv_approve_code              xxcso_sp_decision_sends.approve_code%TYPE;
-- 20090406_N.Yanagitaira T1_0536 Mod START
    lv_employee_number           per_people_f.employee_number%TYPE;
-- 20090406_N.Yanagitaira T1_0536 Mod END
    TYPE sp_decision_send_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.sp_decision_send_id%TYPE INDEX BY BINARY_INTEGER;
    TYPE approve_code_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.approve_code%TYPE INDEX BY BINARY_INTEGER;
    TYPE work_request_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.work_request_type%TYPE INDEX BY BINARY_INTEGER;
    TYPE approval_state_tbl_type IS
      TABLE OF xxcso_sp_decision_sends.approval_state_type%TYPE INDEX BY BINARY_INTEGER;
    lt_sp_decision_send_tbl    sp_decision_send_tbl_type;
    lt_approve_code_tbl        approve_code_tbl_type;
    lt_work_request_tbl        work_request_tbl_type;
    lt_approval_state_tbl      approval_state_tbl_type;
    ln_approve_code_count      NUMBER;
    ln_cust_account_id         NUMBER;
    ln_contract_customer_id    NUMBER;
    lb_notify_flag             BOOLEAN;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_notify_flag := FALSE;
--
    SELECT  xtsdr.operation_mode
           ,xtsdr.sp_decision_header_id
           ,xsdh.application_code
           ,xsdh.status
    INTO    lv_operation_mode
           ,ln_sp_decision_header_id
           ,lv_application_code
           ,lv_status
    FROM    xxcso_tmp_sp_dec_request    xtsdr
           ,xxcso_sp_decision_headers   xsdh
    WHERE   xsdh.sp_decision_header_id = xtsdr.sp_decision_header_id
    ;
--
-- 20090417_N.Yanagitaira T1_0536 Add START
    SELECT   xev.employee_number
    INTO     lv_employee_number 
    FROM     xxcso_employees_v2 xev
    WHERE    xev.user_id = fnd_global.user_id
    ;
-- 20090417_N.Yanagitaira T1_0536 Add END
--
    SELECT  xsds.sp_decision_send_id
           ,xsds.approve_code
           ,xsds.work_request_type
           ,xsds.approval_state_type
    BULK COLLECT INTO
            lt_sp_decision_send_tbl
           ,lt_approve_code_tbl
           ,lt_work_request_tbl
           ,lt_approval_state_tbl
    FROM    xxcso_sp_decision_sends    xsds
    WHERE   xsds.sp_decision_header_id = ln_sp_decision_header_id
    AND     xsds.approve_code         <> cv_approve_init
    ORDER BY xsds.approval_authority_number
    ;
--
    << send_loop >>
    FOR idx IN 1..lt_sp_decision_send_tbl.COUNT
    LOOP
--
      IF ( lv_operation_mode = cv_operation_submit ) THEN
        ---------------------------------
        -- ��o�̏ꍇ
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- �X�e�[�^�X�����F�˗����ɕύX���A�\���񐔂��J�E���g�A�b�v����
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_request
                 ,application_number  = (application_number + 1)
                 ,application_date    = TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                 ,last_updated_by     = DECODE(last_update_date
                                         ,creation_date, created_by
                                         ,fnd_global.user_id
                                        )
                 ,last_update_date    = DECODE(last_update_date
                                         ,creation_date, creation_date
                                         ,SYSDATE
                                        )
                 ,last_update_login   = DECODE(last_update_date
                                         ,creation_date, last_update_login
                                         ,fnd_global.login_id
                                        )
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- ���̉񑗐�������A���ُ�ԋ敪���������ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
                 ,last_updated_by     = DECODE(last_update_date
                                         ,creation_date, created_by
                                         ,fnd_global.user_id
                                        )
                 ,last_update_date    = DECODE(last_update_date
                                         ,creation_date, creation_date
                                         ,SYSDATE
                                        )
                 ,last_update_login   = DECODE(last_update_date
                                         ,creation_date, last_update_login
                                         ,fnd_global.login_id
                                        )
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- �ʒm���[�N�t���[�N��
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- ����I�����Ȃ������ꍇ�͏I��
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_confirm ) THEN
        ---------------------------------
        -- �m�F�̏ꍇ
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- �X�e�[�^�X�����F�˗����ɕύX����
          IF ( lv_status <> cv_status_enabled ) THEN
--
            UPDATE  xxcso_sp_decision_headers
            SET     status              = cv_status_request
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_header_id = ln_sp_decision_header_id
            ;
--
          END IF;
--
          -- �������̉񑗐�������A���ُ�ԋ敪�������ςɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_end
                 /* 2009.04.09 K.Satomura T1_0424�Ή� START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424�Ή� END */
                 ,approval_content    = cv_content_confirm
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          lv_approve_code := lt_approve_code_tbl(idx);
--
        END IF;
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- ���̉񑗐�������A���ُ�ԋ敪���������ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
-- 20090406_N.Yanagitaira T1_0316 Del START
--                 ,approval_date       = NULL
--                 ,approval_content    = NULL
-- 20090406_N.Yanagitaira T1_0316 Del END
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- �ʒm���[�N�t���[�N��
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- ����I�����Ȃ������ꍇ�͏I��
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_approve ) THEN
        ---------------------------------
        -- ���F�̏ꍇ
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- �X�e�[�^�X�����F�˗����ɕύX����
          IF ( lv_status <> cv_status_enabled ) THEN
--
            UPDATE  xxcso_sp_decision_headers
            SET     status              = cv_status_request
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_header_id = ln_sp_decision_header_id
            ;
--
          END IF;
--
          -- �������̉񑗐�������A���ُ�ԋ敪�������ςɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_end
                 /* 2009.04.09 K.Satomura T1_0424�Ή� START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424�Ή� END */
                 ,approval_content    = cv_content_approve
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          lv_approve_code := lt_approve_code_tbl(idx);
--
        END IF;
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_none ) THEN
--
          -- ���̉񑗐�������A���ُ�ԋ敪���������ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_during
-- 20090406_N.Yanagitaira T1_0316 Del START
--                 ,approval_date       = NULL
--                 ,approval_content    = NULL
-- 20090406_N.Yanagitaira T1_0316 Del END
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- �ʒm���[�N�t���[�N��
          xxcso020A02C.main(
             iv_notify_type            => lt_work_request_tbl(idx)
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
-- 20090417_N.Yanagitaira T1_0536 Mod START
--            ,iv_send_employee_number   => lv_application_code
            ,iv_send_employee_number   => lv_employee_number
-- 20090417_N.Yanagitaira T1_0536 Mod END
            ,iv_dest_employee_number   => lt_approve_code_tbl(idx)
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- ����I�����Ȃ������ꍇ�͏I��
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_return ) THEN
        ---------------------------------
        -- �ԋp�̏ꍇ
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- �X�e�[�^�X��ی��ɕύX����
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- �������̉񑗐�������A���ُ�ԋ敪�𖢏����ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 /* 2009.04.09 K.Satomura T1_0424�Ή� START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424�Ή� END */
                 ,approval_content    = cv_content_return
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- ���߂̏����ς̉񑗐�������A���ُ�ԋ敪���������ɐݒ肷��
          IF ( idx <> 1 ) THEN
--
            UPDATE  xxcso_sp_decision_sends
            SET     approval_state_type = cv_approval_state_during
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx-1)
            ;
--
          END IF;
--
          -- �ʒm���[�N�t���[�N��
          xxcso020A02C.main(
             iv_notify_type            => cv_notify_return
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
            ,iv_send_employee_number   => lt_approve_code_tbl(idx)
            ,iv_dest_employee_number   => lv_application_code
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- ����I�����Ȃ������ꍇ�͏I��
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          /* 20090716_abe_0000385 START*/
          -- �������̉񑗐�������A���ُ�ԋ敪�𖢏����ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 ,approval_content    = cv_content_return
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          AND     approval_state_type <> cv_approval_state_none
          ;
          /* 20090716_abe_0000385 END*/
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
      IF ( lv_operation_mode = cv_operation_reject ) THEN
        ---------------------------------
        -- �ی��̏ꍇ
        ---------------------------------
--
        IF ( lt_approval_state_tbl(idx) = cv_approval_state_during ) THEN
--
          -- �X�e�[�^�X��ی��ɕύX����
          UPDATE  xxcso_sp_decision_headers
          SET     status              = cv_status_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          ;
--
          -- �������̉񑗐�������A���ُ�ԋ敪�𖢏����ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 /* 2009.04.09 K.Satomura T1_0424�Ή� START */
                 --,approval_date       = SYSDATE
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 /* 2009.04.09 K.Satomura T1_0424�Ή� END */
                 ,approval_content    = cv_content_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx)
          ;
--
          -- ���߂̏����ς̉񑗐�������A���ُ�ԋ敪���������ɐݒ肷��
          IF ( idx <> 1 ) THEN
--
            UPDATE  xxcso_sp_decision_sends
            SET     approval_state_type = cv_approval_state_during
                   ,last_updated_by     = fnd_global.user_id
                   ,last_update_date    = SYSDATE
                   ,last_update_login   = fnd_global.login_id
            WHERE   sp_decision_send_id = lt_sp_decision_send_tbl(idx-1)
            ;
--
          END IF;
--
          -- �ʒm���[�N�t���[�N��
          xxcso020A02C.main(
             iv_notify_type            => cv_notify_reject
            ,it_sp_decision_header_id  => ln_sp_decision_header_id
            ,iv_send_employee_number   => lt_approve_code_tbl(idx)
            ,iv_dest_employee_number   => lv_application_code
            ,errbuf                    => ov_errbuf
            ,retcode                   => ov_retcode
          );
--
          IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
            -- ����I�����Ȃ������ꍇ�͏I��
            RETURN;
--
          END IF;
--
          lb_notify_flag := TRUE;
--
          /* 20090716_abe_0000385 START*/
          -- �������̉񑗐�������A���ُ�ԋ敪�𖢏����ɐݒ肷��
          UPDATE  xxcso_sp_decision_sends
          SET     approval_state_type = cv_approval_state_none
                 ,approval_date       = xxcso_util_common_pkg.get_online_sysdate
                 ,approval_content    = cv_content_reject
                 ,last_updated_by     = fnd_global.user_id
                 ,last_update_date    = SYSDATE
                 ,last_update_login   = fnd_global.login_id
          WHERE   sp_decision_header_id = ln_sp_decision_header_id
          AND     approval_state_type <> cv_approval_state_none
          ;
          /* 20090716_abe_0000385 END*/
--
          EXIT send_loop;
--
        END IF;
--
      END IF;
--
    END LOOP send_loop;
--
-- 20090406_N.Yanagitaira T1_0316 Add START
    -- �񑗐�̎Ј��ԍ���*����͂����ꍇ�A���ٓ��^���ϓ��e�^���σR�����g������������
    UPDATE  xxcso_sp_decision_sends
    SET     approval_date       = NULL
           ,approval_content    = NULL
           ,approval_comment    = NULL
    WHERE   sp_decision_send_id IN
            (
              SELECT xsds.sp_decision_send_id
              FROM   xxcso_sp_decision_headers xsdh
                    ,xxcso_sp_decision_sends   xsds
              WHERE  xsdh.sp_decision_header_id  = ln_sp_decision_header_id
              AND    xsdh.status                <> cv_status_enabled
              AND    xsds.sp_decision_header_id  = xsdh.sp_decision_header_id
              AND    xsds.approve_code           = cv_approve_init
              AND    xsds.approval_state_type    IN (cv_approval_state_none, cv_approval_state_during)
            )
    ;
-- 20090406_N.Yanagitaira T1_0316 Add END
--
    -- �܂����ɏ��F�҂����邩�ǂ������m�F����
    IF ( lv_operation_mode = cv_operation_approve ) THEN
--
      SELECT  COUNT('x')
      INTO    ln_approve_code_count
      FROM    xxcso_sp_decision_headers  xsdh
             ,xxcso_sp_decision_sends    xsds
      WHERE   xsdh.sp_decision_header_id  = ln_sp_decision_header_id
      AND     xsdh.status                <> cv_status_enabled
      AND     xsds.sp_decision_header_id  = xsdh.sp_decision_header_id
      AND     xsds.approve_code          <> cv_approve_init
      AND     xsds.approval_state_type    IN (cv_approval_state_none, cv_approval_state_during)
      AND     xsds.work_request_type      = cv_request_approve
      AND     ROWNUM                      = 1
      ;
--
      IF ( ln_approve_code_count = 0 ) THEN
--
        -- �ŏI���F�҂̏ꍇ�́A�X�e�[�^�X��L���A
        -- ���F�������ɃV�X�e�����t��ݒ肷��
        UPDATE  xxcso_sp_decision_headers
        SET     status                 = cv_status_enabled
               /* 2009.04.09 K.Satomura T1_0424�Ή� START */
               --,approval_complete_date = SYSDATE
               ,approval_complete_date = xxcso_util_common_pkg.get_online_sysdate
               /* 2009.04.09 K.Satomura T1_0424�Ή� END */
               ,last_updated_by        = fnd_global.user_id
               ,last_update_date       = SYSDATE
               ,last_update_login      = fnd_global.login_id
        WHERE   sp_decision_header_id = ln_sp_decision_header_id
        ;
--
        IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
          -- ����I�����Ȃ������ꍇ�͏I��
          RETURN;
--
        END IF;
--
        -- �}�X�^�A�gAPI�R�[��
        xxcso020A03C.main(
          errbuf                      => ov_errbuf
         ,retcode                     => ov_retcode
         ,it_sp_decision_header_id    => ln_sp_decision_header_id
         ,ot_cust_account_id          => ln_cust_account_id
         ,ot_contract_customer_id     => ln_contract_customer_id
        );
--
        IF ( ov_retcode <> xxcso_common_pkg.gv_status_normal ) THEN
--
          -- ����I�����Ȃ������ꍇ�͏I��
          RETURN;
--
        END IF;
--
        -- �}�X�^�A�gAPI�����ID���Z�b�g����i�ݒu��j
        UPDATE  xxcso_sp_decision_custs
        SET     customer_id                = ln_cust_account_id
        WHERE   sp_decision_header_id      = ln_sp_decision_header_id
        AND     sp_decision_customer_class = '1'
        ;
--
        -- �}�X�^�A�gAPI�����ID���Z�b�g����i�_���j
        UPDATE  xxcso_sp_decision_custs
        SET     customer_id                = ln_contract_customer_id
-- 20090323_N.Yanagitaira T1_0163 Add START
               ,same_install_account_flag  = 'N'
-- 20090323_N.Yanagitaira T1_0163 Add END
        WHERE   sp_decision_header_id      = ln_sp_decision_header_id
        AND     sp_decision_customer_class = '2'
        ;
--
      END IF;
--
    END IF;
--
    IF NOT ( lb_notify_flag ) THEN
--
      IF ( lv_operation_mode IN ( cv_operation_confirm, cv_operation_approve ) ) THEN
--
        -- �ʒm���[�N�t���[�N��
        xxcso020A02C.main(
           iv_notify_type            => cv_notify_approve_end
          ,it_sp_decision_header_id  => ln_sp_decision_header_id
          ,iv_send_employee_number   => lv_approve_code
          ,iv_dest_employee_number   => lv_application_code
          ,errbuf                    => ov_errbuf
          ,retcode                   => ov_retcode
        );
--
      END IF;
--
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END process_request;
--
  /**********************************************************************************
   * Function Name    : process_lock
   * Description      : �g�����U�N�V�������b�N����
   ***********************************************************************************/
  PROCEDURE process_lock(
    in_sp_decision_header_id       IN  NUMBER
   ,iv_sp_decision_number          IN  VARCHAR2
   ,id_last_update_date            IN  DATE
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_lock';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_last_update_date          DATE;
    lb_exception_flag            BOOLEAN;
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_exception_flag := FALSE;
--
    BEGIN
--
      SELECT  xsdh.last_update_date
      INTO    ld_last_update_date
      FROM    xxcso_sp_decision_headers  xsdh
      WHERE   xsdh.sp_decision_header_id = in_sp_decision_header_id
      FOR UPDATE NOWAIT
      ;
--
    EXCEPTION
      WHEN nowait_except THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00002';
--
        lb_exception_flag := TRUE;
    END;
--
    IF ( lb_exception_flag = FALSE ) THEN
--
      if ( id_last_update_date < ld_last_update_date ) THEN
--
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00003';
--
      END IF;
--
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END process_lock;
--
  /**********************************************************************************
   * Function Name    : get_inst_info_parameter
   * Description      : �ݒu���񔻒�
   ***********************************************************************************/
  FUNCTION get_inst_info_parameter(
    in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_inst_info_parameter';
    cv_mc_candidate              CONSTANT VARCHAR2(2)     := '10';
    cv_mc                        CONSTANT VARCHAR2(2)     := '20';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_cust_account_id IS NULL ) THEN
--
      lv_return_value := iv_sp_inst_cust_param;
--
    ELSE
--
      IF ( iv_customer_status IN (cv_mc_candidate, cv_mc) ) THEN
--
        lv_return_value := iv_sp_inst_cust_param;
--
      ELSE
--
        lv_return_value := iv_cust_acct_param;
--
      END IF;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_inst_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_cntr_info_parameter
   * Description      : �_����񔻒�
   ***********************************************************************************/
  FUNCTION get_cntr_info_parameter(
    in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_cntr_info_parameter';
    cv_same                      CONSTANT VARCHAR2(1)     := 'Y';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_contract_customer_id IS NULL ) THEN
--
      IF ( iv_same_install_account_flag = cv_same ) THEN
--
        lv_return_value
          := get_inst_info_parameter(
               in_cust_account_id
              ,iv_customer_status
              ,iv_sp_inst_cust_param
              ,iv_cust_acct_param
             );
--
      ELSE
--
        lv_return_value := iv_sp_cntr_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_cntrct_cust_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_cntr_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm1_info_parameter
   * Description      : BM1��񔻒�
   ***********************************************************************************/
  FUNCTION get_bm1_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_bm1_send_type               IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm1_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    cv_same_inst                 CONSTANT VARCHAR2(1)     := '1';
    cv_same_cntr                 CONSTANT VARCHAR2(1)     := '2';
    cv_other                     CONSTANT VARCHAR2(1)     := '3';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        IF ( iv_bm1_send_type = cv_same_inst ) THEN
--
          lv_return_value
            := get_inst_info_parameter(
                 in_cust_account_id
                ,iv_customer_status
                ,iv_sp_inst_cust_param
                ,iv_cust_acct_param
               );
--
        ELSIF ( iv_bm1_send_type = cv_same_cntr ) THEN
--
          lv_return_value
            := get_cntr_info_parameter(
                 in_contract_customer_id
                ,iv_same_install_account_flag
                ,in_cust_account_id
                ,iv_customer_status
                ,iv_sp_cntr_cust_param
                ,iv_cntrct_cust_param
                ,iv_sp_inst_cust_param
                ,iv_cust_acct_param
               );
--
        ELSE
--
          lv_return_value := iv_sp_vend_cust_param;
--
        END IF;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_bm1_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm2_info_parameter
   * Description      : BM2��񔻒�
   ***********************************************************************************/
  FUNCTION get_bm2_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm2_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        lv_return_value := iv_sp_vend_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_bm2_info_parameter;
--
  /**********************************************************************************
   * Function Name    : get_bm3_info_parameter
   * Description      : BM3��񔻒�
   ***********************************************************************************/
  FUNCTION get_bm3_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_bm3_info_parameter';
    cv_bm_payment_non            CONSTANT VARCHAR2(1)     := '5';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(4000);
  BEGIN
--
    lv_return_value := NULL;
--
    IF ( in_vendor_id IS NULL ) THEN
--
      IF ( iv_bm_payment_type = cv_bm_payment_non ) THEN
--
        lv_return_value := NULL;
--
      ELSE
--
        lv_return_value := iv_sp_vend_cust_param;
--
      END IF;
--
    ELSE
--
      lv_return_value := iv_vendor_param;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_bm3_info_parameter;
--
  /**********************************************************************************
   * Function Name    : calculate_sc_line
   * Description      : �����ʏ����v�Z�i���׍s���Ɓj
   ***********************************************************************************/
  PROCEDURE calculate_sc_line(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
-- E_�{�ғ�_15904 Add Start
   ,iv_bm1_tax_kbn                 IN  VARCHAR2
   ,iv_bm2_tax_kbn                 IN  VARCHAR2
   ,iv_bm3_tax_kbn                 IN  VARCHAR2
-- E_�{�ғ�_15904 Add End
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_sc_line';
-- E_�{�ғ�_15904 Add Start
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_apl_name                  CONSTANT VARCHAR2(5)     := 'XXCSO';
    cv_excluding_tax_kbn         CONSTANT VARCHAR2(1)     := '2';   -- �a�l�ŋ敪�i�Ŕ����j
-- E_�{�ғ�_17052 Add Start
    cv_free_tax_kbn              CONSTANT VARCHAR2(1)     := '3';   -- �a�l�ŋ敪�i��ېŁj
-- E_�{�ғ�_17052 Add End
    cv_flag_y                    CONSTANT VARCHAR2(1)     := 'Y';
    cv_prf_calc_sales_tax_code   CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_SALES_TAX_CODE';
-- E_�{�ғ�_17052 Add Start
    cv_prf_calc_sales_tax_code_2 CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_SALES_TAX_CODE_2';
    cv_prf_calc_quantity         CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_QUANTITY';
-- E_�{�ғ�_17052 Add End
    cv_prf_bks_id                CONSTANT VARCHAR2(100)   := 'GL_SET_OF_BKS_ID';
    cv_msg_xxcso1_00913          CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00913';  -- �v�Z�p�ŃR�[�h�擾�G���[
-- E_�{�ғ�_15904 Add End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_fixed_price                    NUMBER;
    ln_defined_cost_rate              NUMBER;
    ln_cost_price                     NUMBER;
    ln_bm_rate                        NUMBER;
    ln_bm_amount                      NUMBER;
    ln_bm_conv_rate                   NUMBER;
-- E_�{�ғ�_15904 Add Start
    ln_criteria_conv_rate             NUMBER;       -- �W���ł̎Z�o
    ln_bm1_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm2_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm3_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm1_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm2_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm3_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm1_rate                       NUMBER;       -- BM1��
    ln_bm2_rate                       NUMBER;       -- BM2��
    ln_bm3_rate                       NUMBER;       -- BM3��
    ln_bm1_amount                     NUMBER;       -- BM1���z
    ln_bm2_amount                     NUMBER;       -- BM2���z
    ln_bm3_amount                     NUMBER;       -- BM3���z
    ln_bm1_tax_rate                   NUMBER;       -- BM1�x���ŗ�
    ln_bm2_tax_rate                   NUMBER;       -- BM2�x���ŗ�
    ln_bm3_tax_rate                   NUMBER;       -- BM3�x���ŗ�
    lv_tax_code                       VARCHAR2(10); -- �x���ŃR�[�h
    lv_bks_id                         VARCHAR2(50); -- ��v����ID
    lt_tax_rate                       ar_vat_tax_all_b.tax_rate%TYPE;
-- E_�{�ғ�_15904 Add End
-- E_�{�ғ�_17052 Add Start
    lv_tax_code_2                     VARCHAR2(10); -- ����ŃR�[�h
    lt_tax_rate_2                     ar_vat_tax_all_b.tax_rate%TYPE;  -- ����ŗ�
    ln_calc_quantity                  NUMBER;       -- �v�Z�p����
    ln_bm_summary                     NUMBER;       -- �萔�����v
-- E_�{�ғ�_17052 Add End
  BEGIN
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
-- E_�{�ғ�_15904 Add Start
--
    ln_bm1_tax_rate := 0;
    ln_bm2_tax_rate := 0;
    ln_bm3_tax_rate := 0;
--
    ln_bm1_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0'));
    ln_bm2_rate := TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0'));
    ln_bm3_rate := TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    ln_bm1_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0'));
    ln_bm2_amount := TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0'));
    ln_bm3_amount := TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
--
    -- ********************************
    -- * �v���t�@�C�����擾
    -- ********************************
    -- �v�Z�p�x���ŃR�[�h���擾
    lv_tax_code := FND_PROFILE.VALUE( cv_prf_calc_sales_tax_code );
-- E_�{�ғ�_17052 Add Start
    -- �v�Z�p����ŃR�[�h���擾
    lv_tax_code_2 := FND_PROFILE.VALUE( cv_prf_calc_sales_tax_code_2 );
    -- �v�Z�p���ʂ��擾
    ln_calc_quantity := TO_NUMBER ( FND_PROFILE.VALUE( cv_prf_calc_quantity ) );
-- E_�{�ғ�_17052 Add End
    -- ��v����ID���擾
    lv_bks_id   := FND_PROFILE.VALUE( cv_prf_bks_id );
--
-- E_�{�ғ�_15904 Add End
--
    -- �ݒ茴�����擾
    SELECT  TO_NUMBER(flvv.attribute1)
    INTO    ln_defined_cost_rate
    FROM    fnd_lookup_values_vl  flvv
    WHERE   flvv.lookup_type               = 'XXCSO1_SP_RULE_SELL_PRICE'
    AND     flvv.lookup_code               = iv_fixed_price
    AND     flvv.enabled_flag              = 'Y'
    AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    ln_fixed_price := TO_NUMBER(REPLACE(iv_fixed_price, ',', ''));
    on_sales_price := TO_NUMBER(REPLACE(iv_sales_price, ',', ''));
    -- �����v�Z
    ln_cost_price := ln_fixed_price * ln_defined_cost_rate;
--
    -- �e�����v�Z
    on_gross_profit := on_sales_price - ln_cost_price;
--
    -- BM���̍��v�l���v�Z
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    -- BM���z�̍��v�l���v�Z
    ln_bm_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
--
-- E_�{�ғ�_15904 Add Start
--
-- E_�{�ғ�_17052 Add Start
    BEGIN
      -- ����ŗ����擾
      SELECT avtab.tax_rate           -- ����ŗ�
      INTO   lt_tax_rate_2
      FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
      WHERE  avtab.tax_code = lv_tax_code_2
      AND    avtab.set_of_books_id = TO_NUMBER( lv_bks_id )
      AND    NVL( avtab.start_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND    NVL( avtab.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND    avtab.enabled_flag = cv_flag_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,cv_msg_xxcso1_00913
                      );
        ov_errbuf  := ov_errmsg;
    END;
-- E_�{�ғ�_17052 Add End
    -- �Ŕ����̂a�l�ŋ敪���ЂƂł�����ꍇ
    IF   ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn )
      OR ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn )
      OR ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn )
    THEN
      BEGIN
        -- �x���ŗ����擾
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_rate
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lv_tax_code
        AND    avtab.set_of_books_id = TO_NUMBER( lv_bks_id )
        AND    NVL( avtab.start_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        AND    NVL( avtab.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        AND    avtab.enabled_flag = cv_flag_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ov_retcode := xxcso_common_pkg.gv_status_error;
          ov_errmsg  := xxccp_common_pkg.get_msg(
                           cv_apl_name
                          ,cv_msg_xxcso1_00913
                        );
          ov_errbuf  := ov_errmsg;
      END;
      -- �ŋ敪��2:�Ŕ����̏ꍇ�A�擾�����ŗ����x���ŗ��Ƃ���
      -- BM1
      IF ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm1_tax_rate := lt_tax_rate;
      END IF;
      -- BM2
      IF ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm2_tax_rate := lt_tax_rate;
      END IF;
      -- BM3
      IF ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm3_tax_rate := lt_tax_rate;
      END IF;
    END IF;
-- E_�{�ғ�_17052 Del Start
/*
    -- ��ł̌v�Z ���P
    ln_criteria_conv_rate
      -- (�艿�|����)���艿
      :=  ( ln_fixed_price - on_sales_price ) / ln_fixed_price
    ;
    -- BM1���ł̌v�Z ���Q
    ln_bm1_r_conv_rate
      -- �����~�a�l�P�����i100 + �a�l�P����ŗ��j���艿
      :=  ( on_sales_price * ln_bm1_rate / (100 + ln_bm1_tax_rate) ) / ln_fixed_price
    ;
    -- BM1���z�ł̌v�Z ���R
    ln_bm1_a_conv_rate
      --  �a�l�P���z�~100��(100�{�a�l�P����ŗ�)���艿
      :=  ( ln_bm1_amount * 100 / (100 + ln_bm1_tax_rate) ) / ln_fixed_price
    ;
    -- BM2���ł̌v�Z ���S
    ln_bm2_r_conv_rate
      -- �����~�a�l�Q�����i100 + �a�l�Q����ŗ��j���艿
      :=  ( on_sales_price * ln_bm2_rate / (100 + ln_bm2_tax_rate) ) / ln_fixed_price
    ;
    -- BM2���z�ł̌v�Z ���T
    ln_bm2_a_conv_rate
      -- �a�l�Q���z�~100��(100�{�a�l�Q����ŗ�)���艿
      :=  ( ln_bm2_amount * 100 / (100 + ln_bm2_tax_rate) ) / ln_fixed_price
    ;
    -- BM3���ł̌v�Z ���U
    ln_bm3_r_conv_rate
      -- �����~�a�l�R�����i100 + �a�l�R����ŗ��j���艿
      :=  ( on_sales_price * ln_bm3_rate / (100 + ln_bm3_tax_rate) ) / ln_fixed_price
    ;
    -- BM3���z�ł̌v�Z ���V
    ln_bm3_a_conv_rate
      -- �a�l�R���z�~100��(100�{�a�l�R����ŗ�)���艿
      :=  ( ln_bm3_amount * 100 / (100 + ln_bm3_tax_rate) ) / ln_fixed_price
    ;
-- E_�{�ғ�_15904 Add End
    -- �艿���Z�����v�Z
    ln_bm_conv_rate
-- E_�{�ғ�_15904 mod Start
--      := (
--          ((on_sales_price * ln_bm_rate / 100) +
--           (ln_fixed_price - on_sales_price + ln_bm_amount)
--          ) / ln_fixed_price
--         ) * 100;
      -- �i���P�{���Q�{���R�{���S�{���T�{���U�{���V�j�~100
      := (  ln_criteria_conv_rate
          + ln_bm1_r_conv_rate + ln_bm1_a_conv_rate
          + ln_bm2_r_conv_rate + ln_bm2_a_conv_rate
          + ln_bm3_r_conv_rate + ln_bm3_a_conv_rate
          ) * 100
    ;
-- E_�{�ғ�_15904 mod End
*/
-- E_�{�ғ�_17052 Del End
--
-- E_�{�ғ�_17052 Add Start
    -- �ŋ敪�ɉ�����BM�萔�����v�Z����B
    -- �ŋ敪��2:�Ŕ��������3:��ېł̏ꍇ
    IF ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm1_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm1_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm1_rate / 100 * 
                            (100 + ln_bm1_tax_rate ) / 100;
      ln_bm1_a_conv_rate := ln_bm1_amount  * ln_calc_quantity * (100 + ln_bm1_tax_rate) / 100;
    -- �ŋ敪��1:�ō��݂̏ꍇ
    ELSE
      ln_bm1_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm1_rate / 100;
      ln_bm1_a_conv_rate := ln_bm1_amount  * ln_calc_quantity;
    END IF;
    -- BM2��BM1�Ɠ��l�̌v�Z
    IF ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm2_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm2_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm2_rate / 100 * 
                            (100 + ln_bm2_tax_rate ) / 100;
      ln_bm2_a_conv_rate := ln_bm2_amount  * ln_calc_quantity * (100 + ln_bm2_tax_rate) / 100;
    ELSE
      ln_bm2_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm2_rate / 100;
      ln_bm2_a_conv_rate := ln_bm2_amount  * ln_calc_quantity;
    END IF;
    -- BM3��BM1�Ɠ��l�̌v�Z
    IF ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm3_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm3_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm3_rate / 100 * 
                            (100 + ln_bm3_tax_rate ) / 100;
      ln_bm3_a_conv_rate := ln_bm3_amount  * ln_calc_quantity * (100 + ln_bm3_tax_rate) / 100;
    ELSE
      ln_bm3_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm3_rate / 100;
      ln_bm3_a_conv_rate := ln_bm3_amount  * ln_calc_quantity;
    END IF;
    ln_bm_summary := ln_bm1_r_conv_rate + ln_bm1_a_conv_rate + ln_bm2_r_conv_rate + ln_bm2_a_conv_rate + ln_bm3_r_conv_rate + ln_bm3_a_conv_rate;
--
    -- �艿���Z�����v�Z
    ln_bm_conv_rate := (  1 - ( on_sales_price * ln_calc_quantity - ln_bm_summary ) / ( ln_fixed_price * ln_calc_quantity ) ) * 100;
--
-- E_�{�ғ�_17052 Add End
--
    -- �ԋp�l��ݒ�
    ov_bm_rate      := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
    ov_bm_amount    := TO_CHAR(ln_bm_amount, 'FM999G999G999G999G990D90');
    ov_bm_conv_rate := TO_CHAR(ROUND(ln_bm_conv_rate, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END calculate_sc_line;
--
  /**********************************************************************************
   * Function Name    : calculate_cc_line
   * Description      : �ꗥ�����E�e��ʏ����v�Z�i���׍s���Ɓj
   ***********************************************************************************/
  PROCEDURE calculate_cc_line(
    iv_container_type              IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
-- E_�{�ғ�_15904 Add Start
   ,iv_bm1_tax_kbn                 IN  VARCHAR2
   ,iv_bm2_tax_kbn                 IN  VARCHAR2
   ,iv_bm3_tax_kbn                 IN  VARCHAR2
-- E_�{�ғ�_15904 Add End
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_cc_line';
-- E_�{�ғ�_15904 Add Start
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_apl_name                  CONSTANT VARCHAR2(5)     := 'XXCSO';
    cv_excluding_tax_kbn         CONSTANT VARCHAR2(1)     := '2';   -- �a�l�ŋ敪�i�Ŕ����j
-- E_�{�ғ�_17052 Add Start
    cv_free_tax_kbn              CONSTANT VARCHAR2(1)     := '3';   -- �a�l�ŋ敪�i��ېŁj
-- E_�{�ғ�_17052 Add End
    cv_flag_y                    CONSTANT VARCHAR2(1)     := 'Y';
    cv_prf_calc_sales_tax_code   CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_SALES_TAX_CODE';
-- E_�{�ғ�_17052 Add Start
    cv_prf_calc_sales_tax_code_2 CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_SALES_TAX_CODE_2';
    cv_prf_calc_quantity         CONSTANT VARCHAR2(100)   := 'XXCSO1_CALC_QUANTITY';
-- E_�{�ғ�_17052 Add End
    cv_prf_bks_id                CONSTANT VARCHAR2(100)   := 'GL_SET_OF_BKS_ID';
    cv_msg_xxcso1_00913          CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00913';  -- �v�Z�p�ŃR�[�h�擾�G���[
-- E_�{�ғ�_15904 Add End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_fixed_price                    NUMBER;
    ln_discount_amt                   NUMBER;
    ln_defined_cost_rate              NUMBER;
    ln_cost_price                     NUMBER;
    ln_bm_rate                        NUMBER;
    ln_bm_amount                      NUMBER;
    ln_bm_conv_rate                   NUMBER;
-- E_�{�ғ�_15904 Add Start
    ln_criteria_conv_rate             NUMBER;       -- �W���ł̎Z�o
    ln_bm1_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm2_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm3_r_conv_rate                NUMBER;       -- ���ł̎Z�o
    ln_bm1_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm2_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm3_a_conv_rate                NUMBER;       -- ���z�ł̎Z�o
    ln_bm1_rate                       NUMBER;       -- BM1��
    ln_bm2_rate                       NUMBER;       -- BM2��
    ln_bm3_rate                       NUMBER;       -- BM3��
    ln_bm1_amount                     NUMBER;       -- BM1���z
    ln_bm2_amount                     NUMBER;       -- BM2���z
    ln_bm3_amount                     NUMBER;       -- BM3���z
    ln_bm1_tax_rate                   NUMBER;       -- BM1�x���ŗ�
    ln_bm2_tax_rate                   NUMBER;       -- BM2�x���ŗ�
    ln_bm3_tax_rate                   NUMBER;       -- BM3�x���ŗ�
    lv_tax_code                       VARCHAR2(10); -- �ŃR�[�h
    lv_bks_id                         VARCHAR2(50); -- ��v����ID
    lt_tax_rate                       ar_vat_tax_all_b.tax_rate%TYPE;
-- E_�{�ғ�_15904 Add End
-- E_�{�ғ�_17052 Add Start
    lv_tax_code_2                     VARCHAR2(10); -- ����ŃR�[�h
    lt_tax_rate_2                     ar_vat_tax_all_b.tax_rate%TYPE;  -- ����ŗ�
    ln_calc_quantity                  NUMBER;       -- �v�Z�p����
    ln_bm_summary                     NUMBER;       -- �萔�����v
-- E_�{�ғ�_17052 Add End
  BEGIN
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
-- E_�{�ғ�_15904 Add Start
--
    ln_bm1_tax_rate := 0;
    ln_bm2_tax_rate := 0;
    ln_bm3_tax_rate := 0;
--
    ln_bm1_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0'));
    ln_bm2_rate := TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0'));
    ln_bm3_rate := TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    ln_bm1_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0'));
    ln_bm2_amount := TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0'));
    ln_bm3_amount := TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
--
    -- ********************************
    -- * �v���t�@�C�����擾
    -- ********************************
    -- �v�Z�p����ŃR�[�h���擾
    lv_tax_code := FND_PROFILE.VALUE( cv_prf_calc_sales_tax_code );
-- E_�{�ғ�_17052 Add Start
    -- �v�Z�p����ŃR�[�h���擾
    lv_tax_code_2 := FND_PROFILE.VALUE( cv_prf_calc_sales_tax_code_2 );
    -- �v�Z�p���ʂ��擾
    ln_calc_quantity := TO_NUMBER ( FND_PROFILE.VALUE( cv_prf_calc_quantity ) );
-- E_�{�ғ�_17052 Add End
    -- ��v����ID���擾
    lv_bks_id   := FND_PROFILE.VALUE( cv_prf_bks_id );
--
-- E_�{�ғ�_15904 Add End
--
    -- �ݒ�艿�A�ݒ茴�����擾
    SELECT  TO_NUMBER(flvv.attribute2)
           ,TO_NUMBER(flvv.attribute3)
    INTO    ln_fixed_price
           ,ln_defined_cost_rate
    FROM    fnd_lookup_values_vl  flvv
    WHERE   flvv.lookup_type               = 'XXCSO1_SP_RULE_BOTTLE'
    AND     flvv.lookup_code               = iv_container_type
    AND     flvv.enabled_flag              = 'Y'
    AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    -- �艿����̒l���z�擾
    ln_discount_amt := TO_NUMBER(NVL(REPLACE(iv_discount_amt, ',' , ''), 0));
--
    -- �����v�Z
    ln_cost_price  := ln_fixed_price * ln_defined_cost_rate;
--
    -- �����v�Z
    on_sales_price := ln_fixed_price + ln_discount_amt;
--
    -- �e�����v�Z
    on_gross_profit := on_sales_price - ln_cost_price;
--
    -- BM���̍��v�l���v�Z
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm2_bm_rate, ',', ''), '0')) +
                  TO_NUMBER(NVL(REPLACE(iv_bm3_bm_rate, ',', ''), '0'));
--
    -- BM���z�̍��v�l���v�Z
    ln_bm_amount := TO_NUMBER(NVL(REPLACE(iv_bm1_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm2_bm_amt, ',', ''), '0')) +
                    TO_NUMBER(NVL(REPLACE(iv_bm3_bm_amt, ',', ''), '0'));
-- E_�{�ғ�_15904 Add Start
--
-- E_�{�ғ�_17052 Add Start
    BEGIN
      -- ����ŗ����擾
      SELECT avtab.tax_rate           -- ����ŗ�
      INTO   lt_tax_rate_2
      FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
      WHERE  avtab.tax_code = lv_tax_code_2
      AND    avtab.set_of_books_id = TO_NUMBER( lv_bks_id )
      AND    NVL( avtab.start_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND    NVL( avtab.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND    avtab.enabled_flag = cv_flag_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,cv_msg_xxcso1_00913
                      );
        ov_errbuf  := ov_errmsg;
    END;
-- E_�{�ғ�_17052 Add End
    -- �Ŕ����̂a�l�ŋ敪���ЂƂł�����ꍇ
    IF   ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn )
      OR ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn )
      OR ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn )
    THEN
      BEGIN
        -- �x���ŗ����擾
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_rate 
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lv_tax_code
        AND    avtab.set_of_books_id = TO_NUMBER( lv_bks_id )
        AND    NVL( avtab.start_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        AND    NVL( avtab.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate) ) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
        AND    avtab.enabled_flag = cv_flag_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ov_retcode := xxcso_common_pkg.gv_status_error;
          ov_errmsg  := xxccp_common_pkg.get_msg(
                           cv_apl_name
                          ,cv_msg_xxcso1_00913
                        );
          ov_errbuf  := ov_errmsg;
      END;
      -- �ŋ敪��2:�Ŕ����̏ꍇ�A�擾�����ŗ����x���ŗ��Ƃ���
      -- BM1
      IF ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm1_tax_rate := lt_tax_rate;
      END IF;
      -- BM2
      IF ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm2_tax_rate := lt_tax_rate;
      END IF;
      -- BM3
      IF ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn ) THEN
        ln_bm3_tax_rate := lt_tax_rate;
      END IF;
    END IF;
--
-- E_�{�ғ�_17052 Del Start
/*
    -- ��ł̌v�Z ���P
    ln_criteria_conv_rate
      -- (�艿�|����)���艿
      :=  ( ln_fixed_price - on_sales_price ) / ln_fixed_price
    ;
    -- BM1���ł̌v�Z ���Q
    ln_bm1_r_conv_rate
      -- �����~�a�l�P�����i100 + �a�l�P����ŗ��j���艿
      :=  ( on_sales_price * ln_bm1_rate / (100 + ln_bm1_tax_rate) ) / ln_fixed_price
    ;
    -- BM1���z�ł̌v�Z ���R
    ln_bm1_a_conv_rate
      --  �a�l�P���z�~100��(100�{�a�l�P����ŗ�)���艿
      :=  ( ln_bm1_amount * 100 / (100 + ln_bm1_tax_rate) ) / ln_fixed_price
    ;
    -- BM2���ł̌v�Z ���S
    ln_bm2_r_conv_rate
      -- �����~�a�l�Q�����i100 + �a�l�Q����ŗ��j���艿
      :=  ( on_sales_price * ln_bm2_rate / (100 + ln_bm2_tax_rate) ) / ln_fixed_price
    ;
    -- BM2���z�ł̌v�Z ���T
    ln_bm2_a_conv_rate
      -- �a�l�Q���z�~100��(100�{�a�l�Q����ŗ�)���艿
      :=  ( ln_bm2_amount * 100 / (100 + ln_bm2_tax_rate) ) / ln_fixed_price
    ;
    -- BM3���ł̌v�Z ���U
    ln_bm3_r_conv_rate
      -- �����~�a�l�R�����i100 + �a�l�R����ŗ��j���艿
      :=  ( on_sales_price * ln_bm3_rate / (100 + ln_bm3_tax_rate) ) / ln_fixed_price
    ;
    -- BM3���z�ł̌v�Z ���V
    ln_bm3_a_conv_rate
      -- �a�l�R���z�~100��(100�{�a�l�R����ŗ�)���艿
      :=  ( ln_bm3_amount * 100 / (100 + ln_bm3_tax_rate) ) / ln_fixed_price
    ;
-- E_�{�ғ�_15904 Add End
--
    -- �艿���Z�����v�Z
    ln_bm_conv_rate
-- E_�{�ғ�_15904 mod Start
--      := (
--          ((on_sales_price * ln_bm_rate / 100) +
--           (0 - ln_discount_amt + ln_bm_amount)
--          ) / ln_fixed_price
--         ) * 100;
      -- �i���P�{���Q�{���R�{���S�{���T�{���U�{���V�j�~100
      := (  ln_criteria_conv_rate
          + ln_bm1_r_conv_rate + ln_bm1_a_conv_rate
          + ln_bm2_r_conv_rate + ln_bm2_a_conv_rate
          + ln_bm3_r_conv_rate + ln_bm3_a_conv_rate
          ) * 100
    ;
-- E_�{�ғ�_15904 mod End
*/
-- E_�{�ғ�_17052 Del End
--
-- E_�{�ғ�_17052 Add Start
    -- �ŋ敪�ɉ�����BM�萔�����v�Z����B
    -- �ŋ敪��2:�Ŕ��������3:��ېł̏ꍇ
    IF ( NVL(iv_bm1_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm1_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm1_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm1_rate / 100 * 
                            (100 + ln_bm1_tax_rate ) / 100;
      ln_bm1_a_conv_rate := ln_bm1_amount  * ln_calc_quantity * (100 + ln_bm1_tax_rate) / 100;
    -- �ŋ敪��1:�ō��݂̏ꍇ
    ELSE
      ln_bm1_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm1_rate / 100;
      ln_bm1_a_conv_rate := ln_bm1_amount  * ln_calc_quantity;
    END IF;
    -- BM2��BM1�Ɠ��l�̌v�Z
    IF ( NVL(iv_bm2_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm2_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm2_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm2_rate / 100 * 
                            (100 + ln_bm2_tax_rate ) / 100;
      ln_bm2_a_conv_rate := ln_bm2_amount  * ln_calc_quantity * (100 + ln_bm2_tax_rate) / 100;
    ELSE
      ln_bm2_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm2_rate / 100;
      ln_bm2_a_conv_rate := ln_bm2_amount  * ln_calc_quantity;
    END IF;
    -- BM3��BM1�Ɠ��l�̌v�Z
    IF ( NVL(iv_bm3_tax_kbn, '1') = cv_excluding_tax_kbn ) OR ( NVL(iv_bm3_tax_kbn, '1') = cv_free_tax_kbn ) THEN
      ln_bm3_r_conv_rate := on_sales_price * ln_calc_quantity * 100 / (100 + lt_tax_rate_2) * ln_bm3_rate / 100 * 
                            (100 + ln_bm3_tax_rate ) / 100;
      ln_bm3_a_conv_rate := ln_bm3_amount  * ln_calc_quantity * (100 + ln_bm3_tax_rate) / 100;
    ELSE
      ln_bm3_r_conv_rate := on_sales_price * ln_calc_quantity * ln_bm3_rate / 100;
      ln_bm3_a_conv_rate := ln_bm3_amount  * ln_calc_quantity;
    END IF;
    ln_bm_summary := ln_bm1_r_conv_rate + ln_bm1_a_conv_rate + ln_bm2_r_conv_rate + ln_bm2_a_conv_rate + ln_bm3_r_conv_rate + ln_bm3_a_conv_rate;
--
    -- �艿���Z�����v�Z
    ln_bm_conv_rate := (  1 - ( on_sales_price * ln_calc_quantity - ln_bm_summary ) / ( ln_fixed_price * ln_calc_quantity ) ) * 100;
--
-- E_�{�ғ�_17052 Add End
    -- �ԋp�l��ݒ�
    ov_bm_rate      := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
    ov_bm_amount    := TO_CHAR(ln_bm_amount, 'FM999G999G999G999G990D90');
    ov_bm_conv_rate := TO_CHAR(ROUND(ln_bm_conv_rate, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END calculate_cc_line;
--
  /**********************************************************************************
   * Function Name    : calculate_est_year_profit
   * Description      : �T�Z�N�ԑ��v�v�Z
   ***********************************************************************************/
  PROCEDURE calculate_est_year_profit(
    iv_sales_month                 IN  VARCHAR2
   ,iv_sales_gross_margin_rate     IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_construction_charge         IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
   ,iv_install_support_amt         IN  VARCHAR2
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
   ,ov_sales_year                  OUT VARCHAR2
   ,ov_year_gross_margin_amt       OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_install_support_amt_year    OUT VARCHAR2
   ,ov_vd_lease_charge             OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
   ,ov_electricity_amt_year        OUT VARCHAR2
   ,ov_transportation_charge       OUT VARCHAR2
   ,ov_labor_cost_other            OUT VARCHAR2
   ,ov_total_cost                  OUT VARCHAR2
   ,ov_operating_profit            OUT VARCHAR2
   ,ov_operating_profit_rate       OUT VARCHAR2
   ,ov_break_even_point            OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'calculate_est_year_profit';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_sales_month                    NUMBER;
    ln_sales_gross_margin_rate        NUMBER;
    ln_bm_rate                        NUMBER;
    ln_lease_charge_month             NUMBER;
    ln_construction_charge            NUMBER;
    ln_contract_year_date             NUMBER;
    ln_install_support_amt            NUMBER;
    ln_electricity_amt_month          NUMBER;
    ln_sales_year                     NUMBER;
    ln_year_gross_margin_amt          NUMBER;
    ln_vd_sales_charge                NUMBER;
    ln_install_support_amt_year       NUMBER;
    ln_vd_lease_charge                NUMBER;
    ln_electricity_amt_year           NUMBER;
    ln_transportation_charge          NUMBER;
    ln_labor_cost_other               NUMBER;
    ln_total_cost                     NUMBER;
    ln_operating_profit               NUMBER;
    ln_operating_profit_rate          NUMBER;
    ln_break_even_point               NUMBER;
    ln_constraction_chg_rate          NUMBER;
    ln_transportation_chg_rate        NUMBER;
    ln_labor_cost_other_rate          NUMBER;
  BEGIN
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- �H����A�^����A�l����擾
    SELECT  TO_NUMBER(flvv1.attribute1)
           ,TO_NUMBER(flvv2.attribute1)
           ,TO_NUMBER(flvv3.attribute1)
    INTO    ln_constraction_chg_rate
           ,ln_transportation_chg_rate
           ,ln_labor_cost_other_rate
    FROM    fnd_lookup_values_vl  flvv1
           ,fnd_lookup_values_vl  flvv2
           ,fnd_lookup_values_vl  flvv3
    WHERE   flvv1.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv2.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv3.lookup_type               = 'XXCSO1_SP_ROUGH_YEAR_PL'
    AND     flvv1.lookup_code               = 'SP_INSTALLATION_COST_RATE'
    AND     flvv2.lookup_code               = 'SP_SHIPPING_COST_RATE'
    AND     flvv3.lookup_code               = 'SP_STAFF_COST_RATE'
    AND     flvv1.enabled_flag              = 'Y'
    AND     NVL(flvv1.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv1.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     flvv2.enabled_flag              = 'Y'
    AND     NVL(flvv2.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv2.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     flvv3.enabled_flag              = 'Y'
    AND     NVL(flvv3.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(flvv3.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
              >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    ;
--
    -- ���Ԕ���
    ln_sales_month := TO_NUMBER(NVL(REPLACE(iv_sales_month, ',' , ''), 0));
--
    -- ����e����
    ln_sales_gross_margin_rate := TO_NUMBER(NVL(REPLACE(iv_sales_gross_margin_rate, ',' , ''), 0));
--
    -- BM��
    ln_bm_rate := TO_NUMBER(NVL(REPLACE(iv_bm_rate, ',' , ''), 0));
--
    -- ���[�X���i���z�j
    ln_lease_charge_month := TO_NUMBER(NVL(REPLACE(iv_lease_charge_month, ',' , ''), 0));
--
    -- �H����
    ln_construction_charge := TO_NUMBER(NVL(REPLACE(iv_construction_charge, ',' , ''), 0));
--
    -- �_��N��
    ln_contract_year_date := TO_NUMBER(NVL(REPLACE(iv_contract_year_date, ',' , ''), 0));
--
    -- ����ݒu���^��
    ln_install_support_amt := TO_NUMBER(NVL(REPLACE(iv_install_support_amt, ',' , ''), 0));
--
    -- �d�C��i���j
    ln_electricity_amt_month := TO_NUMBER(NVL(REPLACE(iv_electricity_amt_month, ',' , ''), 0));
    IF ( ln_electricity_amt_month = 0 ) THEN
--
      ln_electricity_amt_month
        := ROUND((TO_NUMBER(NVL(REPLACE(iv_electricity_amount, ',', ''), 0)) / 1000), 2);
--
    END IF;
--
    ov_electricity_amt_month := TO_CHAR(ln_electricity_amt_month, 'FM999G999G999G999G990D90');
--
    -- �N�Ԕ���
    ln_sales_year := ln_sales_month * 12;
    ov_sales_year := TO_CHAR(ln_sales_year, 'FM999G999G999G999G990');
--
    -- �N�ԑe�����z
    ln_year_gross_margin_amt := (ln_sales_year * ln_sales_gross_margin_rate) / 100;
    ov_year_gross_margin_amt := TO_CHAR(ln_year_gross_margin_amt, 'FM999G999G999G999G990D90');
--
    -- VD�̔��萔��
    ln_vd_sales_charge := (ln_sales_year * ln_bm_rate) / 100;
    ov_vd_sales_charge := TO_CHAR(ln_vd_sales_charge, 'FM999G999G999G999G990D90');
--
    -- �ݒu���^���^�N
    ln_install_support_amt_year := ln_install_support_amt / ln_contract_year_date / 1000;
    ov_install_support_amt_year := TO_CHAR(
                                     ROUND(ln_install_support_amt_year, 2)
                                    ,'FM999G999G999G999G990D90'
                                   );
--
    -- VD���[�X��
-- 200900507_N.Yanagitaira T1_0200 Mod START
--    ln_vd_lease_charge := ln_lease_charge_month * 12 + 
--                          ln_construction_charge * ln_constraction_chg_rate * 12;
    ln_vd_lease_charge := ln_lease_charge_month * 12 + 
                          ln_construction_charge / ln_contract_year_date;
-- 200900507_N.Yanagitaira T1_0200 Mod END
    ov_vd_lease_charge := TO_CHAR(ln_vd_lease_charge, 'FM999G999G999G999G990D90');
--
    -- �d�C��i�N�j
    ln_electricity_amt_year := ln_electricity_amt_month * 12;
    ov_electricity_amt_year := TO_CHAR(ln_electricity_amt_year, 'FM999G999G999G999G990D90');
--
    -- �^����A
    ln_transportation_charge := ln_sales_year * ln_transportation_chg_rate;
    ov_transportation_charge := TO_CHAR(ln_transportation_charge, 'FM999G999G999G999G990D90');
--
    -- �l����
    ln_labor_cost_other := ln_sales_year * ln_labor_cost_other_rate;
    ov_labor_cost_other := TO_CHAR(ln_labor_cost_other, 'FM999G999G999G999G990D90');
--
    -- ��p���v
    ln_total_cost := ln_vd_sales_charge +
                     ln_vd_lease_charge +
                     ln_electricity_amt_year +
-- 200900507_N.Yanagitaira T1_0200 Add START
                     ln_install_support_amt_year +
-- 200900507_N.Yanagitaira T1_0200 Add END
                     ln_transportation_charge +
                     ln_labor_cost_other;
    ov_total_cost := TO_CHAR(ln_total_cost, 'FM999G999G999G999G990D90');
--
    -- �c�Ɨ��v
    ln_operating_profit := ln_year_gross_margin_amt - ln_total_cost;
    ov_operating_profit := TO_CHAR(ln_operating_profit, 'FM999G999G999G999G990D90');
--
    -- �c�Ɨ��v��
    ln_operating_profit_rate := (ln_operating_profit / ln_sales_year) * 100;
    ov_operating_profit_rate := TO_CHAR(
                                  ROUND(ln_operating_profit_rate, 2)
                                 ,'FM999G999G999G999G990D90'
                                );
--
    -- ���v����_
-- 2009/10/26 K.Satomura E_T4_00075 Mod START
    --ln_break_even_point := (ln_vd_lease_charge +
    --                        ln_electricity_amt_year +
    --                        ln_labor_cost_other
    --                       ) / 
    --                       (
    --                        (ln_year_gross_margin_amt -
    --                         ln_vd_sales_charge -
    --                         ln_transportation_charge
    --                        ) / ln_sales_year
    --                       );
    -- ���v����_ = (A / (1 - (B  / �N�ԑe�����z))) / (����e���� / 100)
    --          A = �u�c���[�X�� + �ݒu���^���^�N + �d�C��i�N�j
    --          B = �u�c�̔��萔�� + �^����` + �l���
    ln_break_even_point := (
                             (ln_vd_lease_charge + ln_install_support_amt_year + ln_electricity_amt_year) /
                             (1 - 
                               (
                                 (ln_vd_sales_charge + ln_transportation_charge + ln_labor_cost_other) / ln_year_gross_margin_amt
                               )
                             )
                           ) / (ln_sales_gross_margin_rate / 100)
                           ;
    --
-- 2009/10/26 K.Satomura E_T4_00075 Mod End
    ov_break_even_point := TO_CHAR(ROUND(ln_break_even_point, 2), 'FM999G999G999G999G990D90');
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END calculate_est_year_profit;
--
  /**********************************************************************************
   * Function Name    : get_gross_profit_rate
   * Description      : �e�����擾
   ***********************************************************************************/
  FUNCTION get_gross_profit_rate(
    in_total_gross_profit          IN  NUMBER
   ,in_total_sales_price           IN  NUMBER
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_gross_profit_rate';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_gross_profit_rate         NUMBER;
  BEGIN
    ln_gross_profit_rate := (in_total_gross_profit / in_total_sales_price) * 100 - 1;
    RETURN TO_CHAR(ROUND(ln_gross_profit_rate, 2), 'FM999G999G999G999G990D90');
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_gross_profit_rate;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_1
   * Description      : ���F�������x���ԍ��P�擾
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_1(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm_conv_rate                IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_1';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_discount_amt         NUMBER;
    ln_bm_conv_rate         NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    IF ( iv_fixed_price IS NOT NULL ) THEN
--
      ln_discount_amt := TO_NUMBER(REPLACE(iv_fixed_price, ',', '')) -
                         TO_NUMBER(REPLACE(iv_sales_price, ',', ''));
--
    ELSE
--
      ln_discount_amt := 0 - TO_NUMBER(REPLACE(iv_discount_amt, ',', ''));
--
    END IF;
    ln_bm_conv_rate := TO_NUMBER(REPLACE(iv_bm_conv_rate, ',', ''));
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                         = 'XXCSO1_SP_WF_RULE_DETAIL_1'
      AND     flvv.enabled_flag                                        = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_discount_amt)        <= ln_discount_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), ln_discount_amt)        >= ln_discount_amt
      AND     NVL(TO_NUMBER(flvv.attribute4), (ln_bm_conv_rate - 1))   < ln_bm_conv_rate
      AND     NVL(TO_NUMBER(flvv.attribute5), ln_bm_conv_rate)        >= ln_bm_conv_rate
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_1;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_2
   * Description      : ���F�������x���ԍ��Q�擾
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_2(
    iv_install_support_amt         IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_install_support_amt  NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    ln_install_support_amt := NVL(TO_NUMBER(REPLACE(iv_install_support_amt, ',', '')), 0);
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_2'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_install_support_amt) 
                                                               <= ln_install_support_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_install_support_amt + 1))
                                                                > ln_install_support_amt
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_2;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_3
   * Description      : ���F�������x���ԍ��R�擾
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_3(
    iv_electricity_amt             IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_3';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_electricity_amt      NUMBER;
    ln_appr_auth_level_num  NUMBER;
--
  BEGIN
--
    ln_electricity_amt := NVL(TO_NUMBER(REPLACE(iv_electricity_amt, ',', '')), 0);
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_3'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_electricity_amt) 
                                                               <= ln_electricity_amt
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_electricity_amt + 1))
                                                                > ln_electricity_amt
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_3;
--
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_4
   * Description      : ���F�������x���ԍ��S�擾
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_4(
    iv_construction_charge         IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_4';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_construction_charge      NUMBER;
    ln_appr_auth_level_num      NUMBER;
--
  BEGIN
--
    ln_construction_charge := NVL(TO_NUMBER(REPLACE(iv_construction_charge, ',', '')), 0) * 1000;
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_4'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     NVL(TO_NUMBER(flvv.attribute2), ln_construction_charge) 
                                                               <= ln_construction_charge
      AND     NVL(TO_NUMBER(flvv.attribute3), (ln_construction_charge + 1))
                                                                > ln_construction_charge
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_4;
--
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� START */
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_5
   * Description      : ���F�������x���ԍ��T�擾
   ***********************************************************************************/
  FUNCTION get_appr_auth_level_num_5(
    iv_bm1_bm_payment_type     IN  VARCHAR2
   ,iv_bm2_bm_payment_type     IN  VARCHAR2
   ,iv_bm3_bm_payment_type     IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_5';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_appr_auth_level_num      NUMBER;
--
  BEGIN
--

    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.attribute1)), 0)
      INTO    ln_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_WF_RULE_DETAIL_5'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     flvv.attribute2 IN (iv_bm1_bm_payment_type
                                 ,iv_bm2_bm_payment_type
                                 ,iv_bm3_bm_payment_type
                                 )
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       ln_appr_auth_level_num := 0;
    END;
--
    RETURN ln_appr_auth_level_num;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_5;
--
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� END */
  /**********************************************************************************
   * Function Name    : get_appr_auth_level_num_0
   * Description      : ���F�������x���ԍ��i�f�t�H���g�j�擾
   ***********************************************************************************/
  PROCEDURE get_appr_auth_level_num_0(
    on_appr_auth_level_num         OUT NUMBER
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_appr_auth_level_num_0';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
--
  BEGIN
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    BEGIN
      SELECT  NVL(MAX(TO_NUMBER(flvv.lookup_code)), 0)
      INTO    on_appr_auth_level_num
      FROM    fnd_lookup_values_vl  flvv
      WHERE   flvv.lookup_type                                  = 'XXCSO1_SP_DECISION_LEVEL'
      AND     flvv.enabled_flag                                 = 'Y'
      AND     flvv.attribute3                                   = '1'
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00307';
      WHEN TOO_MANY_ROWS THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00308';
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_appr_auth_level_num_0;
--
  /**********************************************************************************
   * Function Name    : chk_double_byte_kana
   * Description      : �S�p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte_kana';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
    ln_length                    NUMBER;
--
  BEGIN
--
    lv_return_value := '1';
    ln_length := LENGTH(iv_value);
--
    << dobule_byte_check_loop >>
    FOR idx IN 1..ln_length
    LOOP
--
      lb_return_value := xxccp_common_pkg.chk_double_byte_kana(SUBSTR(iv_value, idx, 1));
--
      IF NOT ( lb_return_value ) THEN
--
        lv_return_value := '0';
        EXIT dobule_byte_check_loop;
--
      END IF;
--
    END LOOP dobule_byte_check_loop;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_double_byte_kana;
--
  /**********************************************************************************
   * Function Name    : chk_tel_format
   * Description      : �d�b�ԍ��`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_tel_format';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lb_return_value := xxccp_common_pkg.chk_tel_format(iv_value);
--
    IF ( lb_return_value ) THEN
--
      lv_return_value := '1';
--
    ELSE
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_tel_format;
--
  /**********************************************************************************
   * Function Name    : conv_number_separate
   * Description      : ���l�Z�p���[�g�ϊ�
   ***********************************************************************************/
  PROCEDURE conv_number_separate(
    iv_sele_number                 IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del Start
--   ,iv_install_support_amt         IN  VARCHAR2
--   ,iv_install_support_amt2        IN  VARCHAR2
--   ,iv_payment_cycle               IN  VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del End
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_sales_month                 IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_vd_sales_charge             IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_contruction_charge          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add Start
   ,iv_contract_year_month         IN  VARCHAR2
   ,iv_contract_start_month        IN  VARCHAR2
   ,iv_contract_end_month          IN  VARCHAR2
   ,iv_ad_assets_amt               IN  VARCHAR2
   ,iv_ad_assets_this_time         IN  VARCHAR2
   ,iv_ad_assets_payment_year      IN  VARCHAR2
   ,iv_install_supp_amt            IN  VARCHAR2
   ,iv_install_supp_this_time      IN  VARCHAR2
   ,iv_install_supp_payment_year   IN  VARCHAR2
   ,iv_intro_chg_amt               IN  VARCHAR2
   ,iv_intro_chg_this_time         IN  VARCHAR2
   ,iv_intro_chg_payment_year      IN  VARCHAR2
   ,iv_intro_chg_per_sales_price   IN  VARCHAR2
   ,iv_intro_chg_per_piece         IN  VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add End
   ,ov_sele_number                 OUT VARCHAR2
   ,ov_contract_year_date          OUT VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del Start
--   ,ov_install_support_amt         OUT VARCHAR2
--   ,ov_install_support_amt2        OUT VARCHAR2
--   ,ov_payment_cycle               OUT VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del End
   ,ov_electricity_amount          OUT VARCHAR2
   ,ov_sales_month                 OUT VARCHAR2
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_lease_charge_month          OUT VARCHAR2
   ,ov_contruction_charge          OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add Start
   ,ov_contract_year_month         OUT VARCHAR2
   ,ov_contract_start_month        OUT VARCHAR2
   ,ov_contract_end_month          OUT VARCHAR2
   ,ov_ad_assets_amt               OUT VARCHAR2
   ,ov_ad_assets_this_time         OUT VARCHAR2
   ,ov_ad_assets_payment_year      OUT VARCHAR2
   ,ov_install_supp_amt            OUT VARCHAR2
   ,ov_install_supp_this_time      OUT VARCHAR2
   ,ov_install_supp_payment_year   OUT VARCHAR2
   ,ov_intro_chg_amt               OUT VARCHAR2
   ,ov_intro_chg_this_time         OUT VARCHAR2
   ,ov_intro_chg_payment_year      OUT VARCHAR2
   ,ov_intro_chg_per_sales_price   OUT VARCHAR2
   ,ov_intro_chg_per_piece         OUT VARCHAR2
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add End
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'conv_number_separate';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_sele_number                 NUMBER;
    ln_contract_year_date          NUMBER;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del Start
--    ln_install_support_amt         NUMBER;
--    ln_install_support_amt2        NUMBER;
--    ln_payment_cycle               NUMBER;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Del End
    ln_electricity_amount          NUMBER;
    ln_sales_month                 NUMBER;
    ln_bm_rate                     NUMBER;
    ln_vd_sales_charge             NUMBER;
    ln_lease_charge_month          NUMBER;
    ln_contruction_charge          NUMBER;
    ln_electricity_amt_month       NUMBER;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add Start
    ln_contract_year_month         NUMBER;
    ln_contract_start_month        NUMBER;
    ln_contract_end_month          NUMBER;
    ln_ad_assets_amt               NUMBER;
    ln_ad_assets_this_time         NUMBER;
    ln_ad_assets_payment_year      NUMBER;
    ln_install_supp_amt            NUMBER;
    ln_install_supp_this_time      NUMBER;
    ln_install_supp_payment_year   NUMBER;
    ln_intro_chg_amt               NUMBER;
    ln_intro_chg_this_time         NUMBER;
    ln_intro_chg_payment_year      NUMBER;
    ln_intro_chg_per_sales_price   NUMBER; --����
    ln_intro_chg_per_piece         NUMBER;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add End
--
  BEGIN
--
    BEGIN
      ln_sele_number := TO_NUMBER(REPLACE(iv_sele_number, ',',''));
      IF ( (ln_sele_number - TRUNC(ln_sele_number)) = 0 ) THEN
        ov_sele_number := TO_CHAR(ln_sele_number, 'FM999G999G999G999G990');
      ELSE
        ov_sele_number := iv_sele_number;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sele_number := iv_sele_number;
    END;
--
    BEGIN
      ln_contract_year_date := TO_NUMBER(REPLACE(iv_contract_year_date, ',',''));
      IF ( (ln_contract_year_date - TRUNC(ln_contract_year_date)) = 0 ) THEN
        ov_contract_year_date := TO_CHAR(ln_contract_year_date, 'FM999G999G999G999G990');
      ELSE
        ov_contract_year_date := iv_contract_year_date;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contract_year_date := iv_contract_year_date;
    END;
--
-- 20141215_K.Kiriu E_�{�ғ�_12565 Mod Start
--    BEGIN
--      ln_install_support_amt := TO_NUMBER(REPLACE(iv_install_support_amt, ',',''));
--      IF ( (ln_install_support_amt - TRUNC(ln_install_support_amt)) = 0 ) THEN
--        ov_install_support_amt := TO_CHAR(ln_install_support_amt, 'FM999G999G999G999G990');
--      ELSE
--        ov_install_support_amt := iv_install_support_amt;
--      END IF;
--    EXCEPTION
--      WHEN OTHERS THEN
--        ov_install_support_amt := iv_install_support_amt;
--    END;
--
--    BEGIN
--      ln_install_support_amt2 := TO_NUMBER(REPLACE(iv_install_support_amt2, ',',''));
--      IF ( (ln_install_support_amt2 - TRUNC(ln_install_support_amt2)) = 0 ) THEN
--        ov_install_support_amt2 := TO_CHAR(ln_install_support_amt2, 'FM999G999G999G999G990');
--      ELSE
--        ov_install_support_amt2 := iv_install_support_amt2;
--      END IF;
--    EXCEPTION
--      WHEN OTHERS THEN
--        ov_install_support_amt2 := iv_install_support_amt2;
--    END;
--
--    BEGIN
--      ln_payment_cycle := TO_NUMBER(REPLACE(iv_payment_cycle, ',',''));
--      IF ( (ln_payment_cycle - TRUNC(ln_payment_cycle)) = 0 ) THEN
--        ov_payment_cycle := TO_CHAR(ln_payment_cycle, 'FM999G999G999G999G990');
--      ELSE
--        ov_payment_cycle := iv_payment_cycle;
--      END IF;
--    EXCEPTION
--      WHEN OTHERS THEN
--        ov_payment_cycle := iv_payment_cycle;
--    END;
--
    BEGIN
      ln_electricity_amount := TO_NUMBER(REPLACE(iv_electricity_amount, ',',''));
      IF ( (ln_electricity_amount - TRUNC(ln_electricity_amount)) = 0 ) THEN
        ov_electricity_amount := TO_CHAR(ln_electricity_amount, 'FM999G999G999G999G990');
      ELSE
        ov_electricity_amount := iv_electricity_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_electricity_amount := iv_electricity_amount;
    END;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Mod End
--
    BEGIN
      ln_sales_month := TO_NUMBER(REPLACE(iv_sales_month, ',',''));
      IF ( (ln_sales_month - TRUNC(ln_sales_month)) = 0 ) THEN
        ov_sales_month := TO_CHAR(ln_sales_month, 'FM999G999G999G999G990');
      ELSE
        ov_sales_month := iv_sales_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sales_month := iv_sales_month;
    END;
--
    BEGIN
      ln_bm_rate := TO_NUMBER(REPLACE(iv_bm_rate, ',',''));
      IF ( (ln_bm_rate - TRUNC(ln_bm_rate, 2)) = 0 ) THEN
        ov_bm_rate := TO_CHAR(ln_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm_rate := iv_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm_rate := iv_bm_rate;
    END;
--
    BEGIN
      ln_vd_sales_charge := TO_NUMBER(REPLACE(iv_vd_sales_charge, ',',''));
      IF ( (ln_vd_sales_charge - TRUNC(ln_vd_sales_charge, 2)) = 0 ) THEN
        ov_vd_sales_charge := TO_CHAR(ln_vd_sales_charge, 'FM999G999G999G999G990D90');
      ELSE
        ov_vd_sales_charge := iv_vd_sales_charge;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_vd_sales_charge := iv_vd_sales_charge;
    END;
--
    BEGIN
      ln_lease_charge_month := TO_NUMBER(REPLACE(iv_lease_charge_month, ',',''));
      IF ( (ln_lease_charge_month - TRUNC(ln_lease_charge_month)) = 0 ) THEN
        ov_lease_charge_month := TO_CHAR(ln_lease_charge_month, 'FM999G999G999G999G990');
      ELSE
        ov_lease_charge_month := iv_lease_charge_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_lease_charge_month := iv_lease_charge_month;
    END;
--
    BEGIN
      ln_contruction_charge := TO_NUMBER(REPLACE(iv_contruction_charge, ',',''));
      IF ( (ln_contruction_charge - TRUNC(ln_contruction_charge)) = 0 ) THEN
        ov_contruction_charge := TO_CHAR(ln_contruction_charge, 'FM999G999G999G999G990');
      ELSE
        ov_contruction_charge := iv_contruction_charge;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contruction_charge := iv_contruction_charge;
    END;
--
    BEGIN
      ln_electricity_amt_month := TO_NUMBER(REPLACE(iv_electricity_amt_month, ',',''));
      IF ( (ln_electricity_amt_month - TRUNC(ln_electricity_amt_month, 2)) = 0 ) THEN
        ov_electricity_amt_month := TO_CHAR(ln_electricity_amt_month, 'FM999G999G999G999G990D90');
      ELSE
        ov_electricity_amt_month := iv_electricity_amt_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_electricity_amt_month := iv_electricity_amt_month;
    END;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add Start
--
    BEGIN
      ln_contract_year_month := TO_NUMBER(REPLACE(iv_contract_year_month, ',',''));
      IF ( (ln_contract_year_month - TRUNC(ln_contract_year_month)) = 0 ) THEN
        ov_contract_year_month := TO_CHAR(ln_contract_year_month, 'FM999G999G999G999G990');
      ELSE
        ov_contract_year_month := iv_contract_year_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contract_year_month := iv_contract_year_month;
    END;
--
    BEGIN
      ln_contract_start_month := TO_NUMBER(REPLACE(iv_contract_start_month, ',',''));
      IF ( (ln_contract_start_month - TRUNC(ln_contract_start_month)) = 0 ) THEN
        ov_contract_start_month := TO_CHAR(ln_contract_start_month, 'FM999G999G999G999G990');
      ELSE
        ov_contract_start_month := iv_contract_start_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contract_start_month := iv_contract_start_month;
    END;
--
    BEGIN
      ln_contract_end_month := TO_NUMBER(REPLACE(iv_contract_end_month, ',',''));
      IF ( (ln_contract_end_month - TRUNC(ln_contract_end_month)) = 0 ) THEN
        ov_contract_end_month := TO_CHAR(ln_contract_end_month, 'FM999G999G999G999G990');
      ELSE
        ov_contract_end_month := iv_contract_end_month;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_contract_end_month := iv_contract_end_month;
    END;
--
    BEGIN
      ln_ad_assets_amt := TO_NUMBER(REPLACE(iv_ad_assets_amt, ',',''));
      IF ( (ln_ad_assets_amt - TRUNC(ln_ad_assets_amt)) = 0 ) THEN
        ov_ad_assets_amt := TO_CHAR(ln_ad_assets_amt, 'FM999G999G999G999G990');
      ELSE
        ov_ad_assets_amt := iv_ad_assets_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_ad_assets_amt := iv_ad_assets_amt;
    END;
--
    BEGIN
      ln_ad_assets_this_time := TO_NUMBER(REPLACE(iv_ad_assets_this_time, ',',''));
      IF ( (ln_ad_assets_this_time - TRUNC(ln_ad_assets_this_time)) = 0 ) THEN
        ov_ad_assets_this_time := TO_CHAR(ln_ad_assets_this_time, 'FM999G999G999G999G990');
      ELSE
        ov_ad_assets_this_time := iv_ad_assets_this_time;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_ad_assets_this_time := iv_ad_assets_this_time;
    END;
--
    BEGIN
      ln_ad_assets_payment_year := TO_NUMBER(REPLACE(iv_ad_assets_payment_year, ',',''));
      IF ( (ln_ad_assets_payment_year - TRUNC(ln_ad_assets_payment_year)) = 0 ) THEN
        ov_ad_assets_payment_year := TO_CHAR(ln_ad_assets_payment_year, 'FM999G999G999G999G990');
      ELSE
        ov_ad_assets_payment_year := iv_ad_assets_payment_year;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_ad_assets_payment_year := iv_ad_assets_payment_year;
    END;
--
    BEGIN
      ln_install_supp_amt := TO_NUMBER(REPLACE(iv_install_supp_amt, ',',''));
      IF ( (ln_install_supp_amt - TRUNC(ln_install_supp_amt)) = 0 ) THEN
        ov_install_supp_amt := TO_CHAR(ln_install_supp_amt, 'FM999G999G999G999G990');
      ELSE
        ov_install_supp_amt := iv_install_supp_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_install_supp_amt := iv_install_supp_amt;
    END;
--
    BEGIN
      ln_install_supp_this_time := TO_NUMBER(REPLACE(iv_install_supp_this_time, ',',''));
      IF ( (ln_install_supp_this_time - TRUNC(ln_install_supp_this_time)) = 0 ) THEN
        ov_install_supp_this_time := TO_CHAR(ln_install_supp_this_time, 'FM999G999G999G999G990');
      ELSE
        ov_install_supp_this_time := iv_install_supp_this_time;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_install_supp_this_time := iv_install_supp_this_time;
    END;
--
    BEGIN
      ln_install_supp_payment_year := TO_NUMBER(REPLACE(iv_install_supp_payment_year, ',',''));
      IF ( (ln_install_supp_payment_year - TRUNC(ln_install_supp_payment_year)) = 0 ) THEN
        ov_install_supp_payment_year := TO_CHAR(ln_install_supp_payment_year, 'FM999G999G999G999G990');
      ELSE
        ov_install_supp_payment_year := iv_install_supp_payment_year;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_install_supp_payment_year := iv_install_supp_payment_year;
    END;
--
    BEGIN
      ln_intro_chg_amt := TO_NUMBER(REPLACE(iv_intro_chg_amt, ',',''));
      IF ( (ln_intro_chg_amt - TRUNC(ln_intro_chg_amt)) = 0 ) THEN
        ov_intro_chg_amt := TO_CHAR(ln_intro_chg_amt, 'FM999G999G999G999G990');
      ELSE
        ov_intro_chg_amt := iv_intro_chg_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_intro_chg_amt := iv_intro_chg_amt;
    END;
--
    BEGIN
      ln_intro_chg_this_time := TO_NUMBER(REPLACE(iv_intro_chg_this_time, ',',''));
      IF ( (ln_intro_chg_this_time - TRUNC(ln_intro_chg_this_time)) = 0 ) THEN
        ov_intro_chg_this_time := TO_CHAR(ln_intro_chg_this_time, 'FM999G999G999G999G990');
      ELSE
        ov_intro_chg_this_time := iv_intro_chg_this_time;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_intro_chg_this_time := iv_intro_chg_this_time;
    END;
--
    BEGIN
      ln_intro_chg_payment_year := TO_NUMBER(REPLACE(iv_intro_chg_payment_year, ',',''));
      IF ( (ln_intro_chg_payment_year - TRUNC(ln_intro_chg_payment_year)) = 0 ) THEN
        ov_intro_chg_payment_year := TO_CHAR(ln_intro_chg_payment_year, 'FM999G999G999G999G990');
      ELSE
        ov_intro_chg_payment_year := iv_intro_chg_payment_year;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_intro_chg_payment_year := iv_intro_chg_payment_year;
    END;
--
    BEGIN
      ln_intro_chg_per_sales_price := TO_NUMBER(REPLACE(iv_intro_chg_per_sales_price, ',',''));
      IF ( (ln_intro_chg_per_sales_price - TRUNC(ln_intro_chg_per_sales_price, 2)) = 0 ) THEN
        ov_intro_chg_per_sales_price := TO_CHAR(ln_intro_chg_per_sales_price, 'FM999G999G999G999G990D90');
      ELSE
        ov_intro_chg_per_sales_price := iv_intro_chg_per_sales_price;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_intro_chg_per_sales_price := iv_intro_chg_per_sales_price;
    END;
--
    BEGIN
      ln_intro_chg_per_piece := TO_NUMBER(REPLACE(iv_intro_chg_per_piece, ',',''));
      IF ( (ln_intro_chg_per_piece - TRUNC(ln_intro_chg_per_piece)) = 0 ) THEN
        ov_intro_chg_per_piece := TO_CHAR(ln_intro_chg_per_piece, 'FM999G999G999G999G990');
      ELSE
        ov_intro_chg_per_piece := iv_intro_chg_per_piece;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_intro_chg_per_piece := iv_intro_chg_per_piece;
    END;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add End
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END conv_number_separate;
--
  /**********************************************************************************
   * Function Name    : conv_line_number_separate
   * Description      : ���l�Z�p���[�g�ϊ��i���ׁj
   ***********************************************************************************/
  PROCEDURE conv_line_number_separate(
    iv_sales_price                  IN  VARCHAR2
   ,iv_discount_amt                 IN  VARCHAR2
   ,iv_total_bm_rate                IN  VARCHAR2
   ,iv_total_bm_amount              IN  VARCHAR2
   ,iv_total_bm_conv_rate           IN  VARCHAR2
   ,iv_bm1_bm_rate                  IN  VARCHAR2
   ,iv_bm1_bm_amount                IN  VARCHAR2
   ,iv_bm2_bm_rate                  IN  VARCHAR2
   ,iv_bm2_bm_amount                IN  VARCHAR2
   ,iv_bm3_bm_rate                  IN  VARCHAR2
   ,iv_bm3_bm_amount                IN  VARCHAR2
   ,ov_sales_price                  OUT VARCHAR2
   ,ov_discount_amt                 OUT VARCHAR2
   ,ov_total_bm_rate                OUT VARCHAR2
   ,ov_total_bm_amount              OUT VARCHAR2
   ,ov_total_bm_conv_rate           OUT VARCHAR2
   ,ov_bm1_bm_rate                  OUT VARCHAR2
   ,ov_bm1_bm_amount                OUT VARCHAR2
   ,ov_bm2_bm_rate                  OUT VARCHAR2
   ,ov_bm2_bm_amount                OUT VARCHAR2
   ,ov_bm3_bm_rate                  OUT VARCHAR2
   ,ov_bm3_bm_amount                OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'conv_line_number_separate';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_sales_price                  NUMBER;
    ln_discount_amt                 NUMBER;
    ln_total_bm_rate                NUMBER;
    ln_total_bm_amount              NUMBER;
    ln_total_bm_conv_rate           NUMBER;
    ln_bm1_bm_rate                  NUMBER;
    ln_bm1_bm_amount                NUMBER;
    ln_bm2_bm_rate                  NUMBER;
    ln_bm2_bm_amount                NUMBER;
    ln_bm3_bm_rate                  NUMBER;
    ln_bm3_bm_amount                NUMBER;
--
  BEGIN
--
    BEGIN
      ln_sales_price := TO_NUMBER(REPLACE(iv_sales_price, ',',''));
      IF ( (ln_sales_price - TRUNC(ln_sales_price)) = 0 ) THEN
        ov_sales_price := TO_CHAR(ln_sales_price, 'FM999G999G999G999G990');
      ELSE
        ov_sales_price := iv_sales_price;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_sales_price := iv_sales_price;
    END;
--
    BEGIN
      ln_discount_amt := TO_NUMBER(REPLACE(iv_discount_amt, ',',''));
      IF ( (ln_discount_amt - TRUNC(ln_discount_amt)) = 0 ) THEN
        ov_discount_amt := TO_CHAR(ln_discount_amt, 'FM999G999G999G999G990');
      ELSE
        ov_discount_amt := iv_discount_amt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_discount_amt := iv_discount_amt;
    END;
--
    BEGIN
      ln_total_bm_rate := TO_NUMBER(REPLACE(iv_total_bm_rate, ',',''));
      IF ( (ln_total_bm_rate - TRUNC(ln_total_bm_rate, 2)) = 0 ) THEN
        ov_total_bm_rate := TO_CHAR(ln_total_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_rate := iv_total_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_rate := iv_total_bm_rate;
    END;
--
    BEGIN
      ln_total_bm_amount := TO_NUMBER(REPLACE(iv_total_bm_amount, ',',''));
      IF ( (ln_total_bm_amount - TRUNC(ln_total_bm_amount, 2)) = 0 ) THEN
        ov_total_bm_amount := TO_CHAR(ln_total_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_amount := iv_total_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_amount := iv_total_bm_amount;
    END;
--
    BEGIN
      ln_total_bm_conv_rate := TO_NUMBER(REPLACE(iv_total_bm_conv_rate, ',',''));
      IF ( (ln_total_bm_conv_rate - TRUNC(ln_total_bm_conv_rate, 2)) = 0 ) THEN
        ov_total_bm_conv_rate := TO_CHAR(ln_total_bm_conv_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_total_bm_conv_rate := iv_total_bm_conv_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_total_bm_conv_rate := iv_total_bm_conv_rate;
    END;
--
    BEGIN
      ln_bm1_bm_rate := TO_NUMBER(REPLACE(iv_bm1_bm_rate, ',',''));
      IF ( (ln_bm1_bm_rate - TRUNC(ln_bm1_bm_rate, 2)) = 0 ) THEN
        ov_bm1_bm_rate := TO_CHAR(ln_bm1_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm1_bm_rate := iv_bm1_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm1_bm_rate := iv_bm1_bm_rate;
    END;
--
    BEGIN
      ln_bm1_bm_amount := TO_NUMBER(REPLACE(iv_bm1_bm_amount, ',',''));
      IF ( (ln_bm1_bm_amount - TRUNC(ln_bm1_bm_amount, 2)) = 0 ) THEN
        ov_bm1_bm_amount := TO_CHAR(ln_bm1_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm1_bm_amount := iv_bm1_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm1_bm_amount := iv_bm1_bm_amount;
    END;
--
    BEGIN
      ln_bm2_bm_rate := TO_NUMBER(REPLACE(iv_bm2_bm_rate, ',',''));
      IF ( (ln_bm2_bm_rate - TRUNC(ln_bm2_bm_rate, 2)) = 0 ) THEN
        ov_bm2_bm_rate := TO_CHAR(ln_bm2_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm2_bm_rate := iv_bm2_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm2_bm_rate := iv_bm2_bm_rate;
    END;
--
    BEGIN
      ln_bm2_bm_amount := TO_NUMBER(REPLACE(iv_bm2_bm_amount, ',',''));
      IF ( (ln_bm2_bm_amount - TRUNC(ln_bm2_bm_amount, 2)) = 0 ) THEN
        ov_bm2_bm_amount := TO_CHAR(ln_bm2_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm2_bm_amount := iv_bm2_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm2_bm_amount := iv_bm2_bm_amount;
    END;
--
    BEGIN
      ln_bm3_bm_rate := TO_NUMBER(REPLACE(iv_bm3_bm_rate, ',',''));
      IF ( (ln_bm3_bm_rate - TRUNC(ln_bm3_bm_rate, 2)) = 0 ) THEN
        ov_bm3_bm_rate := TO_CHAR(ln_bm3_bm_rate, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm3_bm_rate := iv_bm3_bm_rate;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm3_bm_rate := iv_bm3_bm_rate;
    END;
--
    BEGIN
      ln_bm3_bm_amount := TO_NUMBER(REPLACE(iv_bm3_bm_amount, ',',''));
      IF ( (ln_bm3_bm_amount - TRUNC(ln_bm3_bm_amount, 2)) = 0 ) THEN
        ov_bm3_bm_amount := TO_CHAR(ln_bm3_bm_amount, 'FM999G999G999G999G990D90');
      ELSE
        ov_bm3_bm_amount := iv_bm3_bm_amount;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        ov_bm3_bm_amount := iv_bm3_bm_amount;
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END conv_line_number_separate;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  /**********************************************************************************
   * Function Name    : chk_double_byte
   * Description      : �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_double_byte';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
    lb_return_value := xxccp_common_pkg.chk_double_byte(iv_value);
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_double_byte;
--
  /**********************************************************************************
   * Function Name    : chk_single_byte_kana
   * Description      : ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
   ***********************************************************************************/
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_single_byte_kana';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_return_value              VARCHAR2(1);
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    lv_return_value := '1';
--
-- 20090605_N.Yanagitaira T1_1307 Mod START
--    lb_return_value := xxccp_common_pkg.chk_single_byte_kana(iv_value);
    -- ���ʊ֐��̔��p�����`�F�b�N���s��
    lb_return_value := xxccp_common_pkg.chk_single_byte(iv_value);
-- 20090605_N.Yanagitaira T1_1307 Mod END
--
    IF NOT ( lb_return_value ) THEN
--
      lv_return_value := '0';
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_single_byte_kana;
--
-- 20090427_N.Yanagitaira T1_0708 Add END
--
-- 20091129_D.Abe E_�{�ғ�_00106 Mod START
--
  /**********************************************************************************
   * Function Name    : chk_account_many
   * Description      : �A�J�E���g��������
   ***********************************************************************************/
  PROCEDURE chk_account_many(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_account_many';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
    lv_errmsg                    VARCHAR2(2000);
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR l_account_cur
    IS
      SELECT account_number
      FROM   xxcso_cust_accounts_v xcav1,
             (SELECT party_id
              FROM   xxcso_cust_accounts_v  xtsdr
              WHERE  account_number = iv_account_number
             )xcav2
      WHERE xcav1.party_id = xcav2.party_id 
      ORDER BY account_number
    ;
    -- *** ���[�J���E���R�[�h *** 
    l_account_cur_rec  l_account_cur%ROWTYPE;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_count := 0;
    lv_errmsg:=NULL;
    -- �J�[�\���I�[�v��
    OPEN l_account_cur;
--
    <<account_loop>>
    LOOP
      FETCH l_account_cur INTO l_account_cur_rec;
--
      EXIT WHEN l_account_cur%NOTFOUND
        OR l_account_cur%ROWCOUNT = 0;
      IF (ln_count = 0 ) THEN
        lv_errmsg :=  l_account_cur_rec.account_number;
      ELSE
        lv_errmsg := lv_errmsg || ',' || l_account_cur_rec.account_number;
      END IF;
      ln_count := ln_count + 1;
--
    END LOOP account_loop;
--
    -- �J�[�\���E�N���[�Y
    CLOSE l_account_cur;

    IF (ln_count > 1) THEN
      ov_errmsg := lv_errmsg;
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_account_many;
--
-- 20091129_D.Abe E_�{�ғ�_00106 Mod END
-- 20100112_D.Abe E_�{�ғ�_00823 Mod START
  /**********************************************************************************
   * Function Name    : chk_cust_site_uses
   * Description      : �ڋq�g�p�ړI�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_cust_site_uses(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_cust_site_uses';
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ===============================
    cv_ship_to_site_code    CONSTANT VARCHAR2(30) := 'SHIP_TO';
    cv_bill_to_site_code    CONSTANT VARCHAR2(30) := 'BILL_TO';
    cv_site_use_status      CONSTANT VARCHAR2(30) := 'A';
    cv_site_use_lookup_type CONSTANT VARCHAR2(30) := 'SITE_USE_CODE';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
    lv_errmsg                    VARCHAR2(2000);
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR l_site_uses_cur
    IS
      -- �ڋq�g�p�ړI�̎擾(�o�א�E������ȊO)
      SELECT flvv.meaning         meaning
      FROM   hz_cust_accounts     hca
            ,hz_cust_acct_sites   hcas
            ,hz_cust_site_uses    hcsu
            ,fnd_lookup_values_vl flvv
      WHERE  hca.account_number  = iv_account_number
      AND    hca.cust_account_id = hcas.cust_account_id
      AND    hcas.cust_acct_site_id  = hcsu.cust_acct_site_id
      AND    (
               (hcsu.site_use_code  <> cv_ship_to_site_code)
               AND
               (hcsu.site_use_code  <> cv_bill_to_site_code)
             )
      AND    hcsu.status        = cv_site_use_status
      AND    flvv.lookup_type   = cv_site_use_lookup_type
      AND    flvv.lookup_code   = hcsu.site_use_code
      ;

    -- *** ���[�J���E���R�[�h *** 
    l_site_uses_cur_rec  l_site_uses_cur%ROWTYPE;

--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    ln_count := 0;
    lv_errmsg:=NULL;
    -- �J�[�\���I�[�v��
    OPEN l_site_uses_cur;
--
    <<site_uses_loop>>
    LOOP
      FETCH l_site_uses_cur INTO l_site_uses_cur_rec;
--
      EXIT WHEN l_site_uses_cur%NOTFOUND
        OR l_site_uses_cur%ROWCOUNT = 0;
      IF (ln_count = 0 ) THEN
        lv_errmsg :=  l_site_uses_cur_rec.meaning;
      ELSE
        lv_errmsg := lv_errmsg || '�A' || l_site_uses_cur_rec.meaning;
      END IF;
      ln_count := ln_count + 1;
--
    END LOOP site_uses_loop;
--
    -- �J�[�\���E�N���[�Y
    CLOSE l_site_uses_cur;

    IF (ln_count > 0) THEN
      ov_errmsg := lv_errmsg;
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_cust_site_uses;
--
-- 20100112_D.Abe E_�{�ғ�_00823 Mod END
-- 20100115_D.Abe E_�{�ғ�_00950 Mod START
  /**********************************************************************************
   * Function Name    : chk_validate_db
   * Description      : �c�a�X�V����`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_validate_db(
    in_sp_decision_header_id      IN  NUMBER
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_validate_db';

    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_last_update_date          DATE;
    lb_return_value              BOOLEAN;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    lb_return_value := FALSE;

    SELECT  xsdh.last_update_date
    INTO    ld_last_update_date
    FROM    xxcso_sp_decision_headers  xsdh
    WHERE   xsdh.sp_decision_header_id = in_sp_decision_header_id;

    IF ( id_last_update_date < ld_last_update_date ) THEN
      lb_return_value := TRUE;
    END IF;

    IF (lb_return_value) THEN
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
    --
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_validate_db;
--
-- 20100115_D.Abe E_�{�ғ�_00950 Mod END
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add START
  /**********************************************************************************
   * Function Name    : get_contract_end_period
   * Description      : �_��I�����Ԏ擾
   ***********************************************************************************/
  PROCEDURE get_contract_end_period(
    iv_contract_year_date         IN  VARCHAR2
   ,iv_contract_year_month        IN  VARCHAR2
   ,iv_contract_start_year        IN  VARCHAR2
   ,iv_contract_start_month       IN  VARCHAR2
   ,iv_contract_end_year          IN  VARCHAR2
   ,iv_contract_end_month         IN  VARCHAR2
   ,ov_contract_end               OUT VARCHAR2
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_contract_end_period';
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cn_months                    CONSTANT NUMBER          := 12;         --����
    cv_slash                     CONSTANT VARCHAR2(1)     := '/';        --�X���b�V��
    cv_date_format_yyyymm        CONSTANT VARCHAR2(7)     := 'YYYY/MM';  --DATE�t�H�[�}�b�g(YYYY/MM)
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_number_of_months          NUMBER;
    lv_contract_year_month       VARCHAR2(7);
--
  BEGIN
--
    --������
    ov_retcode             := xxcso_common_pkg.gv_status_normal;
    ov_contract_end        := NULL;
    ln_number_of_months    := 0;
    lv_contract_year_month := NULL;
--
    --�_��N���������ɕϊ����_�񌎐��ƍ��Z(1�N��(�������܂߂��-1�����Ƃ���))
    ln_number_of_months := ( TO_NUMBER( iv_contract_year_date ) * cn_months ) + TO_NUMBER( iv_contract_year_month ) -1;
    --�_����ԏI���̕ҏW
    lv_contract_year_month := TO_CHAR( 
                                 TO_DATE( iv_contract_end_year || cv_slash || iv_contract_end_month, cv_date_format_yyyymm)
                                ,cv_date_format_yyyymm
                              );
--
    --�_����ԊJ�n(�N)(��)�ƌ_�񌎐����A�_����ԏI��(�N���j���擾
    SELECT  TO_CHAR(
              ADD_MONTHS(
                TO_DATE( iv_contract_start_year || cv_slash || iv_contract_start_month, cv_date_format_yyyymm )
               ,ln_number_of_months )
             ,cv_date_format_yyyymm )
    INTO    ov_contract_end
    FROM    DUAL
    ;
    --�_����Ԃ̃`�F�b�N
    IF ( lv_contract_year_month <> ov_contract_end ) THEN
      ov_retcode := xxcso_common_pkg.gv_status_warn;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_contract_end_period;
-- 20141215_K.Kiriu E_�{�ғ�_12565 Add END
-- 20180516_Y.Shoji E_�{�ғ�_14989 Add START
  /**********************************************************************************
   * Function Name    : get_required_check_flag
   * Description      : �H���A�ݒu�����݊��ԕK�{�t���O�擾
   ***********************************************************************************/
  PROCEDURE get_required_check_flag(
    iv_business_type              IN  VARCHAR2
   ,iv_biz_cond_type              IN  VARCHAR2
   ,on_check_count                OUT NUMBER
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_required_check_flag';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_check_count               NUMBER;
--
  BEGIN
--
    --������
    ov_retcode             := xxcso_common_pkg.gv_status_normal;
    ov_errbuf              := NULL;
    ov_errmsg              := NULL;
    on_check_count         := 0;
--
    BEGIN
      SELECT  COUNT(0) check_count
      INTO    ln_check_count
      FROM    fnd_lookup_values_vl  flvv1  -- �Ƒԕ��ށi�����ށj
             ,fnd_lookup_values_vl  flvv2  -- �Ƒԕ��ށi�����ށj
      WHERE   flvv1.lookup_code     = iv_biz_cond_type
      AND     flvv1.lookup_type     = 'XXCMM_CUST_GYOTAI_SHO'
      AND     flvv1.enabled_flag    = 'Y'
      AND     NVL(flvv1.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv1.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                    >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     flvv1.attribute1      = flvv2.lookup_code
      AND     flvv2.lookup_type     = 'XXCMM_CUST_GYOTAI_CHU'
      AND     flvv2.attribute2      = 'Y'
      AND     flvv2.enabled_flag    = 'Y'
      AND     NVL(flvv2.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                    <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv2.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                    >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_check_count := 0;
    END;
--
    on_check_count := ln_check_count;
--
    BEGIN
      SELECT  COUNT(0) check_count
      INTO    ln_check_count
      FROM    fnd_lookup_values_vl  flvv  -- �Ǝ�敪
      WHERE   flvv.lookup_code     = iv_business_type
      AND     flvv.lookup_type     = 'XXCMM_CUST_GYOTAI_KBN'
      AND     flvv.enabled_flag    = 'Y'
      AND     flvv.attribute1      = 'Y'
      AND     NVL(flvv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                   <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      AND     NVL(flvv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate))
                                   >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_check_count := 0;
    END;
--
      on_check_count := on_check_count + ln_check_count;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_required_check_flag;
-- 20180516_Y.Shoji E_�{�ғ�_14989 Add END
-- E_�{�ғ�_16293 Add START
  /**********************************************************************************
   * Function Name    : chk_vendor_inbalid
   * Description      : �d���斳�����`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_vendor_inbalid(
    iv_vendor_code                IN  VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_vendor_inbalid';
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cd_process_date              CONSTANT DATE            := TRUNC(xxcso_util_common_pkg.get_online_sysdate()); -- �Ɩ����t
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_v_invalid_date             DATE;
    ld_v_site_invalid_date        DATE;
    lv_v_site_code                VARCHAR2(15);
--
  BEGIN
--
    --������
    ov_retcode              := xxcso_common_pkg.gv_status_normal;
--
    BEGIN
      SELECT  pv.end_date_active    AS end_date_active    -- �d���斳����
            , pvs.inactive_date     AS inactive_date      -- �d����T�C�g������
      INTO    ld_v_invalid_date
            , ld_v_site_invalid_date
      FROM  po_vendors            pv
          , po_vendor_sites       pvs
      WHERE pv.segment1     = iv_vendor_code
        AND pv.vendor_id    = pvs.vendor_id
        AND pvs.attribute4  IS NOT NULL
        AND pvs.attribute4  <> '5'
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ld_v_invalid_date       := NULL;
        ld_v_site_invalid_date  := NULL;
    END;
--
    IF (    ( ld_v_invalid_date IS NOT NULL AND ld_v_invalid_date <= cd_process_date)
        OR  ( ld_v_site_invalid_date IS NOT NULL AND ld_v_site_invalid_date <= cd_process_date ) ) THEN
      ov_retcode := xxcso_common_pkg.gv_status_error;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_vendor_inbalid;
-- E_�{�ғ�_16293 Add END
END xxcso_020001j_pkg;
/
