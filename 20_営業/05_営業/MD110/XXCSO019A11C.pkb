CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A11C(body)
 * Description      : �w�肳�ꂽ���_CD�E��������ɁA�������Ă���c�ƈ����A����ɑ΂���
 *                    �L�����Ԓ��̒S���ڋq�̃f�[�^���擾���ACSV�`���ŏo�̓t�@�C���ɏo�͂��܂��B
 * MD.050           : MD050_CSO_019_A11_�S���c�ƈ��ꗗ�f�[�^�o��
 *
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  output_csv_rec              �o�̓t�@�C���ւ̃f�[�^�o�� (A-3)
 *  submain                     ���C�������v���V�[�W��
 *                                  �S���c�ƈ��f�[�^���o (A-2)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010-03-19    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2011-03-15    1.1   Naoki.Horigome   E_�{�ғ�_01946�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
--  gn_skip_cnt               NUMBER;                    -- �X�L�b�v����
--
  gv_company_cd             VARCHAR2(2000);            -- ��ЃR�[�h(�Œ�l001)
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A11C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
--
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00610';  -- �p�����[�^���_CD
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00611';  -- �p�����[�^���
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00612';  -- �p�����[�^����G���[���b�Z�[�W
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[ 
  -- 2011-03-15 Ver1.1 Add Naoki.Horigome strat
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00239';  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
  -- �g�[�N���R�[�h
  cv_tkn_bs_cd           CONSTANT VARCHAR2(20)  := 'BASE_CD';
  cv_tkn_stndrd_dt       CONSTANT VARCHAR2(20)  := 'STANDARD_DATE';
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<<�Ɩ��������t�A����t>>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'od_standard_date = ';
  --
  cv_dt_format           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- ���t����
  cv_mnth_format         CONSTANT VARCHAR2(10)  := 'MM';                   -- ���t����
  --
  cv_whick_log           CONSTANT VARCHAR2(3)   := 'LOG';                  -- ���O
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gb_hdr_put_flg         BOOLEAN DEFAULT FALSE; -- CSV�w�b�_�[�o�̓t���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`
  TYPE g_get_data_rtype IS RECORD(
     account_number         xxcso_cust_resources_v.account_number%TYPE          -- �ڋqCD
    ,party_name             xxcso_cust_accounts_v.party_name%TYPE               -- �ڋq��
    ,customer_class_code    xxcso_cust_accounts_v.customer_class_code%TYPE      -- �ڋq�敪
    ,customer_class_name    xxcso_cust_accounts_v.customer_class_name%TYPE      -- �ڋq�敪��
    ,customer_status        xxcso_cust_accounts_v.customer_status%TYPE          -- �ڋq�X�e�[�^�X
    ,customer_status_name   fnd_lookup_values_vl.meaning%TYPE                   -- �ڋq�X�e�[�^�X��
    ,business_low_type      xxcso_cust_accounts_v.business_low_type%TYPE        -- �Ƒԏ�����
    ,business_low_type_name fnd_lookup_values_vl.meaning%TYPE                   -- �Ƒԏ����ޖ�
    ,sale_base_code         xxcso_cust_accounts_v.sale_base_code%TYPE           -- ���㋒�_
    ,rsv_sale_base_act_date xxcso_cust_accounts_v.rsv_sale_base_act_date%TYPE   -- �\�񔄏㋒�_�L���J�n��
    ,rsv_sale_base_code     xxcso_cust_accounts_v.rsv_sale_base_code%TYPE       -- �\�񔄏㋒�_
    ,route_no               xxcso_cust_routes_v.route_number%TYPE               -- ���[�gNo
    ,employee_number        xxcso_resources_v2.employee_number%TYPE             -- �S���c�ƈ�CD
    ,full_name              xxcso_resources_v2.full_name%TYPE                   -- �S���c�ƈ���
    ,start_date_active      xxcso_cust_resources_v.start_date_active%TYPE       -- �S���c�ƈ��J�n��
    ,end_date_active        xxcso_cust_resources_v.end_date_active%TYPE         -- �S���c�ƈ��I����
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code        IN         VARCHAR2     -- ���_�R�[�h
   ,iv_standard_date    IN         VARCHAR2     -- ���(1�F���� / 2�F����)
   ,od_process_date     OUT NOCOPY DATE         -- �Ɩ��������t
   ,od_standard_date    OUT NOCOPY DATE         -- ����t
   ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- �v���O������
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    -- �Q�ƃ^�C�v
    cv_lkup_tp_standard_date CONSTANT VARCHAR2(100) := 'XXCSO1_STANDARD_DATE';
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_ths_mnth             CONSTANT VARCHAR2(1)   := '1';             -- ����
    cv_nxt_mnth             CONSTANT VARCHAR2(1)   := '2';             -- ����
    -- *** ���[�J���ϐ� ***
    ld_sysdate           DATE;             -- �V�X�e�����t
    lv_msg               VARCHAR2(5000);   -- ���b�Z�[�W�i�[�p
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    lt_standard_date_name fnd_lookup_values_vl.meaning%TYPE;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================
    -- �V�X�e�����t�擾���� 
    -- =====================
    ld_sysdate := SYSDATE;
--
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    -- ===================
    -- ������̎擾���� 
    -- ===================
    SELECT flv.meaning
    INTO   lt_standard_date_name
    FROM   fnd_lookup_values_vl flv
    WHERE  flv.lookup_type = cv_lkup_tp_standard_date
    AND    flv.lookup_code = iv_standard_date
    ;
    
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
    -- =============================
    -- ���̓p�����[�^���b�Z�[�W�o�� 
    -- =============================
    -- �p�����[�^���_CD
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_bs_cd             -- �g�[�N���R�[�h1
                  ,iv_token_value1 => iv_base_code             -- �g�[�N���l1
                 );
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
--
    -- �p�����[�^���
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_stndrd_dt         -- �g�[�N���R�[�h1
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--                  ,iv_token_value1 => iv_standard_date         -- �g�[�N���l1
                  ,iv_token_value1 => lt_standard_date_name         -- �g�[�N���l1
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
                 );
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
--
    -- ��s�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );
--
    -- =============================
    -- �p�����[�^.����Ó����`�F�b�N
    -- =============================
    -- �p�����[�^.�����1�܂���2�łȂ��ꍇ�̓G���[
    IF ((iv_standard_date <> cv_ths_mnth)
      AND (iv_standard_date <> cv_nxt_mnth)) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_03             -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- �Ɩ��������t�擾����
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- ����t���o����
    -- =====================
    IF (iv_standard_date = cv_ths_mnth) THEN
      od_standard_date := od_process_date; -- �Ɩ��������t
    ELSIF (iv_standard_date = cv_nxt_mnth) THEN
      -- �Ɩ��������̗�������
      SELECT TRUNC(ADD_MONTHS(od_process_date,1),cv_mnth_format)
      INTO   od_standard_date
      FROM   dual
      ;
    END IF;
    -- *** DEBUG_LOG START ***
    -- �Ɩ��������t�A����t�����O�o��
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || TO_CHAR(od_process_date,cv_dt_format)|| CHR(10) ||
                 cv_debug_msg3 || TO_CHAR(od_standard_date,cv_dt_format)|| CHR(10) ||
                 ''
    );
    -- *** DEBUG_LOG END ***
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_rec
   * Description      : �o�̓t�@�C���ւ̃f�[�^�o�� (A-3)
   ***********************************************************************************/
  PROCEDURE output_csv_rec(
     i_cst_rsurcs_dt_rec    IN         g_get_data_rtype       -- �S���c�ƈ��f�[�^
    ,iv_base_code           IN         VARCHAR2               -- ���_�R�[�h
    ,id_standard_date       IN         DATE                   -- ����t
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'output_csv_rec';       -- �v���O������
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
    --
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--    cv_hdr_output_dt           CONSTANT VARCHAR2(100)  := '�o�͊��';           -- �o�͊��
--    cv_hdr_bs_cd               CONSTANT VARCHAR2(100)  := '�o�͋��_CD';           -- �o�͋��_CD
--    cv_hdr_acct_num            CONSTANT VARCHAR2(100)  := '�ڋqCD';               -- �ڋqCD
--    cv_hdr_prty_nm             CONSTANT VARCHAR2(100)  := '�ڋq��';               -- �ڋq��
--    cv_hdr_cust_cls_cd         CONSTANT VARCHAR2(100)  := '�ڋq�敪';             -- �ڋq�敪
--    cv_hdr_cust_cls_nm         CONSTANT VARCHAR2(100)  := '�ڋq�敪��';           -- �ڋq�敪��
--    cv_hdr_cust_stts           CONSTANT VARCHAR2(100)  := '�ڋq�X�e�[�^�X';       -- �ڋq�X�e�[�^�X
--    cv_hdr_cust_stts_nm        CONSTANT VARCHAR2(100)  := '�ڋq�X�e�[�^�X��';     -- �ڋq�X�e�[�^�X��
--    cv_hdr_bsnss_lw_tp         CONSTANT VARCHAR2(100)  := '�Ƒԏ�����';           -- �Ƒԏ�����
--    cv_hdr_bsnss_lw_tp_nm      CONSTANT VARCHAR2(100)  := '�Ƒԏ����ޖ�';         -- �Ƒԏ����ޖ�
--    cv_hdr_sl_bs_cd            CONSTANT VARCHAR2(100)  := '���㋒�_CD';           -- ���㋒�_CD
--    cv_hdr_rsv_sl_bs_act_dt    CONSTANT VARCHAR2(100)  := '�\�񔄏㋒�_�J�n��';   -- �\�񔄏㋒�_�J�n��
--    cv_hdr_rsv_sl_bs_cd        CONSTANT VARCHAR2(100)  := '�\�񔄏㋒�_';         -- �\�񔄏㋒�_
--    cv_hdr_route_no            CONSTANT VARCHAR2(100)  := '���[�gNo';             -- ���[�gNo
--    cv_hdr_emply_num           CONSTANT VARCHAR2(100)  := '�S���c�ƈ�CD';         -- �S���c�ƈ�CD
--    cv_hdr_fll_nm              CONSTANT VARCHAR2(100)  := '�S���c�ƈ���';         -- �S���c�ƈ���
--    cv_hdr_strt_dt_active      CONSTANT VARCHAR2(100)  := '�S���c�ƈ��J�n��';     -- �S���c�ƈ��J�n��
--    cv_hdr_ed_dt_active        CONSTANT VARCHAR2(100)  := '�S���c�ƈ��I����';     -- �S���c�ƈ��I����
    cv_hdr_output            CONSTANT VARCHAR2(100)  := 'XXCSO1_SALES_MEMBER_LIST_HEAD';  -- �o�̓w�b�_��
    
    -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
    --
    cb_false                   CONSTANT BOOLEAN        := FALSE;
    cb_true                    CONSTANT BOOLEAN        := TRUE;
    -- *** ���[�J���ϐ� ***
    lv_hdr_data                VARCHAR2(4000);   --�w�b�_�[�s�i�[�p
    lv_line_data               VARCHAR2(4000);   --���׍s�i�[�p
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    lv_hdr_data  := NULL;
    lv_line_data := NULL;
    -- ==========================
    -- CSV�f�[�^�̍��ږ����o��
    -- ==========================
    IF (gb_hdr_put_flg = cb_false) THEN
      -- 2011-03-15 Ver1.1 Mod Naoki.Horigome start
--      lv_hdr_data := cv_sep_wquot || cv_hdr_output_dt        || cv_sep_wquot || cv_sep_com ||   -- �o�͊��
--                     cv_sep_wquot || cv_hdr_bs_cd            || cv_sep_wquot || cv_sep_com ||   -- �o�͋��_CD
--                     cv_sep_wquot || cv_hdr_acct_num         || cv_sep_wquot || cv_sep_com ||   -- �ڋqCD
--                     cv_sep_wquot || cv_hdr_prty_nm          || cv_sep_wquot || cv_sep_com ||   -- �ڋq��
--                     cv_sep_wquot || cv_hdr_cust_cls_cd      || cv_sep_wquot || cv_sep_com ||   -- �ڋq�敪
--                     cv_sep_wquot || cv_hdr_cust_cls_nm      || cv_sep_wquot || cv_sep_com ||   -- �ڋq�敪��
--                     cv_sep_wquot || cv_hdr_cust_stts        || cv_sep_wquot || cv_sep_com ||   -- �ڋq�X�e�[�^�X
--                     cv_sep_wquot || cv_hdr_cust_stts_nm     || cv_sep_wquot || cv_sep_com ||   -- �ڋq�X�e�[�^�X��
--                     cv_sep_wquot || cv_hdr_bsnss_lw_tp      || cv_sep_wquot || cv_sep_com ||   -- �Ƒԏ�����
--                     cv_sep_wquot || cv_hdr_bsnss_lw_tp_nm   || cv_sep_wquot || cv_sep_com ||   -- �Ƒԏ����ޖ�
--                     cv_sep_wquot || cv_hdr_sl_bs_cd         || cv_sep_wquot || cv_sep_com ||   -- ���㋒�_CD
--                     cv_sep_wquot || cv_hdr_rsv_sl_bs_act_dt || cv_sep_wquot || cv_sep_com ||   -- �\�񔄏㋒�_�J�n��
--                     cv_sep_wquot || cv_hdr_rsv_sl_bs_cd     || cv_sep_wquot || cv_sep_com ||   -- �\�񔄏㋒�_
--                     cv_sep_wquot || cv_hdr_route_no         || cv_sep_wquot || cv_sep_com ||   -- ���[�gNo
--                     cv_sep_wquot || cv_hdr_emply_num        || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ�CD
--                     cv_sep_wquot || cv_hdr_fll_nm           || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ���
--                     cv_sep_wquot || cv_hdr_strt_dt_active   || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ��J�n��
--                     cv_sep_wquot || cv_hdr_ed_dt_active     || cv_sep_wquot                    -- �S���c�ƈ��I����
--                     ;
--
      -- ==========================
      -- �Q�ƃ^�C�v�̎擾
      -- ==========================
--
      -- �w�b�_��
      SELECT flv.attribute1 || flv.attribute2
      INTO   lv_hdr_data
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type = cv_hdr_output;
      -- 2011-03-15 Ver1.1 Mod Naoki.Horigome end
--
      -- �w�b�_�[�̏o��
      fnd_file.put_line(
                        which  => FND_FILE.OUTPUT
                       ,buff   => lv_hdr_data
                       );
      gb_hdr_put_flg := cb_true;
    END IF;
    -- ==========================
    -- �S���c�ƈ��f�[�^
    -- ==========================
    lv_line_data := cv_sep_wquot || TO_CHAR(id_standard_date, cv_dt_format)    || cv_sep_wquot || cv_sep_com ||   -- �o�͊��
                    cv_sep_wquot || iv_base_code                               || cv_sep_wquot || cv_sep_com ||   -- �o�͋��_CD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.account_number         || cv_sep_wquot || cv_sep_com ||   -- �ڋqCD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.party_name             || cv_sep_wquot || cv_sep_com ||   -- �ڋq��
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_class_code    || cv_sep_wquot || cv_sep_com ||   -- �ڋq�敪
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_class_name    || cv_sep_wquot || cv_sep_com ||   -- �ڋq�敪��
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_status        || cv_sep_wquot || cv_sep_com ||   -- �ڋq�X�e�[�^�X
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.customer_status_name   || cv_sep_wquot || cv_sep_com ||   -- �ڋq�X�e�[�^�X��
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.business_low_type      || cv_sep_wquot || cv_sep_com ||   -- �Ƒԏ�����
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.business_low_type_name || cv_sep_wquot || cv_sep_com ||   -- �Ƒԏ����ޖ�
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.sale_base_code         || cv_sep_wquot || cv_sep_com ||   -- ���㋒�_CD
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.rsv_sale_base_act_date, cv_dt_format) || cv_sep_wquot || cv_sep_com ||   -- �\�񔄏㋒�_�J�n��
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.rsv_sale_base_code     || cv_sep_wquot || cv_sep_com ||   -- �\�񔄏㋒�_
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.route_no               || cv_sep_wquot || cv_sep_com ||   -- ���[�gNo
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.employee_number        || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ�CD
                    cv_sep_wquot || i_cst_rsurcs_dt_rec.full_name              || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ���
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.start_date_active, cv_dt_format) || cv_sep_wquot || cv_sep_com ||   -- �S���c�ƈ��J�n��
                    cv_sep_wquot || TO_CHAR(i_cst_rsurcs_dt_rec.end_date_active, cv_dt_format)   || cv_sep_wquot                    -- �S���c�ƈ��I����
                   ;
    -- �w�b�_�[�̏o��
    fnd_file.put_line(
                      which  => FND_FILE.OUTPUT
                     ,buff   => lv_line_data
                     );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_base_code        IN         VARCHAR2   -- ���_�R�[�h
    ,iv_standard_date    IN         VARCHAR2   -- ���(1�F���� / 2�F����)
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
    -- �p�����[�^���
    cv_ths_mnth             CONSTANT VARCHAR2(1)   := '1';             -- ����
    cv_nxt_mnth             CONSTANT VARCHAR2(1)   := '2';             -- ����
    -- �Q�ƃ^�C�v
    cv_lkup_tp_kokyaku_status CONSTANT VARCHAR2(100) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_lkup_tp_gyotai_sho     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_SHO';
    -- �ڋq�X�e�[�^�X
    cv_cst_clss_cd_cust       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '10'; -- �ڋq�敪���ڋq
    cv_cst_clss_cd_uesama     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '12'; -- �ڋq�敪����l�ڋq
    cv_cst_clss_cd_cyclic     CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '15'; -- �ڋq�敪������
    cv_cst_clss_cd_tonya      CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '16'; -- �ڋq�敪���≮������
    cv_cst_clss_cd_plan       CONSTANT xxcso_cust_accounts_v.customer_class_code%TYPE := '17'; -- �ڋq�敪���v��
    -- �ڋq�敪�R�[�h
    cv_cst_stts_mc_cnddt      CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '10'; -- �ڋq�X�e�[�^�X���l�b���
    cv_cst_stts_mc            CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '20'; -- �ڋq�X�e�[�^�X���l�b
    cv_cst_stts_sp_dcsn       CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '25'; -- �ڋq�X�e�[�^�X���r�o���ٍ�
    cv_cst_stts_apprvd        CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '30'; -- �ڋq�X�e�[�^�X�����F��
    cv_cst_stts_cstmr         CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '40'; -- �ڋq�X�e�[�^�X���ڋq
    cv_cst_stts_brk           CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '50'; -- �ڋq�X�e�[�^�X���x�~
    cv_cst_stts_abrt_apprvd   CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '90'; -- �ڋq�X�e�[�^�X�����~���ٍ�
    cv_cst_stts_nt_applcbl    CONSTANT xxcso_cust_accounts_v.customer_status%TYPE     := '99'; -- �ڋq�X�e�[�^�X���ΏۊO
    --
    cv_no                     CONSTANT VARCHAR2(1)                                    :=  'N';
    -- *** ���[�J���ϐ� ***
    ld_process_date           DATE;                             -- �Ɩ��������t
    ld_standard_date          DATE;                             -- ���
    lv_standard_date          VARCHAR2(10);                     -- ���̓p�����[�^�F���
    lv_base_code              VARCHAR2(150);                    -- ���̓p�����[�^�F���_CD
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR    get_cst_rsurcs_data_cur
    IS
      SELECT xcrv.account_number         account_number         --�ڋqCD
      ,      xcav.party_name             party_name             --�ڋq��
      ,      xcav.customer_class_code    customer_class_code    --�ڋq�敪
      ,      xcav.customer_class_name    customer_class_name    --�ڋq�敪��
      ,      xcav.customer_status        customer_status        --�ڋq�X�e�[�^�X
      ,      (
              SELECT flv.meaning
              FROM   fnd_lookup_values_vl flv
              WHERE  flv.lookup_type = cv_lkup_tp_kokyaku_status
              AND    flv.lookup_code = xcav.customer_status
             ) customer_status_name                             --�ڋq�X�e�[�^�X��
      ,      xcav.business_low_type      business_low_type      --�Ƒԏ�����
      ,      (
              SELECT flv.meaning
              FROM   fnd_lookup_values_vl flv
              WHERE  flv.lookup_type = cv_lkup_tp_gyotai_sho
              AND    flv.lookup_code = xcav.business_low_type
             ) business_low_type_name                           --�Ƒԏ����ޖ�
      ,      xcav.sale_base_code         sale_base_code         --���㋒�_
      ,      xcav.rsv_sale_base_act_date rsv_sale_base_act_date --�\�񔄏㋒�_�L���J�n��
      ,      xcav.rsv_sale_base_code     rsv_sale_base_code     --�\�񔄏㋒�_
      ,      (
              SELECT xcrtv.route_number
              FROM   xxcso_cust_routes_v xcrtv
              WHERE  xcrtv.account_number = xcrv.account_number
              AND    ld_standard_date BETWEEN xcrtv.start_date_active AND NVL(xcrtv.end_date_active,ld_standard_date)
              AND    ROWNUM=1
             ) route_no                                         --���[�gNo
      ,      xrv2.employee_number        employee_number        --�S���c�ƈ�CD
      ,      xrv2.full_name              full_name              --�S���c�ƈ���
      ,      xcrv.start_date_active      start_date_active      --�S���c�ƈ��J�n��
      ,      xcrv.end_date_active        end_date_active        --�S���c�ƈ��I����
      FROM   xxcso_resources_v2 xrv2
      ,      ( --�I�������������̃��\�[�X�O���[�v�̂�
               SELECT jrgb.attribute1    rsg_dept_code,
                      jrgm.resource_id   resource_id
               FROM   jtf_rs_groups_b jrgb,
                      jtf_rs_group_members jrgm
               WHERE  NVL(jrgb.end_date_active, ld_process_date) >= ld_process_date
               AND    jrgm.delete_flag = cv_no
               AND    jrgm.group_id = jrgb.group_id
             ) jrgmo
      ,      xxcso_cust_resources_v xcrv   -- �ڋq�S���c�ƈ��r���[
      ,      xxcso_cust_accounts_v  xcav   -- �ڋq�}�X�^�r���[
      WHERE  jrgmo.rsg_dept_code  = lv_base_code
      AND    xrv2.resource_id     = jrgmo.resource_id
      AND    (xxcso_util_common_pkg.get_rs_base_code(jrgmo.resource_id, ld_standard_date) = jrgmo.rsg_dept_code)
      AND    xcrv.employee_number =  xrv2.employee_number
      AND    ld_standard_date BETWEEN xcrv.start_date_active AND NVL(xcrv.end_date_active,ld_standard_date)
      AND    xcav.account_number  =  xcrv.account_number
      AND     ( 
                (lv_standard_date = cv_ths_mnth AND (xcav.sale_base_code = jrgmo.rsg_dept_code OR xcav.sale_base_code IS NULL))
                OR
                (lv_standard_date = cv_nxt_mnth AND (xcav.sale_base_code IS NULL ))
                OR
                (lv_standard_date = cv_nxt_mnth AND (
                                                     xcav.sale_base_code = jrgmo.rsg_dept_code   --���㋒�_���w�苒�_
                                                     AND 
                                                     (
                                                       xcav.rsv_sale_base_act_date IS NULL       --�\�񂪂Ȃ�
                                                       OR 
                                                       xcav.rsv_sale_base_act_date > ld_standard_date  --�\�񂪗����P����薢��
                                                      )
                                                     )
                )
                OR
                (lv_standard_date = cv_nxt_mnth AND (
                                                     xcav.rsv_sale_base_code = jrgmo.rsg_dept_code  --�\�񔄏㋒�_���w�苒�_
                                                     AND
                                                     xcav.rsv_sale_base_act_date >= ld_standard_date --�\�񂪗����P���ȍ~
                                                    )
                )
              )
      AND    (
               ((xcav.customer_class_code IS NULL) AND (xcav.customer_status IN (cv_cst_stts_mc_cnddt,cv_cst_stts_mc)))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_cust)) AND (xcav.customer_status IN (cv_cst_stts_mc_cnddt ,cv_cst_stts_mc,
                                                                                                  cv_cst_stts_sp_dcsn  ,cv_cst_stts_apprvd,
                                                                                                  cv_cst_stts_cstmr    ,cv_cst_stts_brk
               )))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_uesama)) AND (xcav.customer_status IN (cv_cst_stts_apprvd,cv_cst_stts_cstmr)))
               OR
               ((xcav.customer_class_code IN (cv_cst_clss_cd_cyclic,cv_cst_clss_cd_tonya,cv_cst_clss_cd_plan)) AND (xcav.customer_status IN (cv_cst_stts_nt_applcbl)))
             )
      ORDER BY xrv2.employee_number
              ,route_no
              ,xcrv.account_number
    ;
    -- *** ���[�J���E���R�[�h ***
    l_cst_rsurcs_data_rec   get_cst_rsurcs_data_cur%ROWTYPE;
    l_get_data_rec          g_get_data_rtype;
    -- *** ���[�J���E��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--    gn_skip_cnt   :=0;
    -- ���̓p�����[�^��ϐ��Ɋi�[
    lv_base_code     := iv_base_code;
    lv_standard_date := iv_standard_date;
--
    -- ================================
    -- A-1.��������
    -- ================================
    init(
       iv_base_code        => lv_base_code      -- ���_�R�[�h
      ,iv_standard_date    => lv_standard_date  -- ���(1�F���� / 2�F����)
      ,od_process_date     => ld_process_date   -- �Ɩ��������t
      ,od_standard_date    => ld_standard_date  -- ����t
      ,ov_errbuf           => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- A-2.�S���c�ƈ��f�[�^���o
    -- ================================
    -- �J�[�\���I�[�v��
    OPEN get_cst_rsurcs_data_cur;
--
    <<get_data_loop>>
    LOOP
      FETCH get_cst_rsurcs_data_cur INTO l_cst_rsurcs_data_rec;
      -- �����Ώی����i�[
      gn_target_cnt := get_cst_rsurcs_data_cur%ROWCOUNT;
--
      EXIT WHEN get_cst_rsurcs_data_cur%NOTFOUND
      OR  get_cst_rsurcs_data_cur%ROWCOUNT = 0;
      -- ���R�[�h�ϐ�������
      l_get_data_rec := NULL;
      -- �擾�f�[�^���i�[
      l_get_data_rec.account_number          := l_cst_rsurcs_data_rec.account_number;             -- �ڋqCD
      l_get_data_rec.party_name              := l_cst_rsurcs_data_rec.party_name;                 -- �ڋq��
      l_get_data_rec.customer_class_code     := l_cst_rsurcs_data_rec.customer_class_code;        -- �ڋq�敪
      l_get_data_rec.customer_class_name     := l_cst_rsurcs_data_rec.customer_class_name;        -- �ڋq�敪��
      l_get_data_rec.customer_status         := l_cst_rsurcs_data_rec.customer_status;            -- �ڋq�X�e�[�^�X
      l_get_data_rec.customer_status_name    := l_cst_rsurcs_data_rec.customer_status_name;       -- �ڋq�X�e�[�^�X��
      l_get_data_rec.business_low_type       := l_cst_rsurcs_data_rec.business_low_type;          -- �Ƒԏ�����
      l_get_data_rec.business_low_type_name  := l_cst_rsurcs_data_rec.business_low_type_name;     -- �Ƒԏ����ޖ�
      l_get_data_rec.sale_base_code          := l_cst_rsurcs_data_rec.sale_base_code;             -- ���㋒�_
      l_get_data_rec.rsv_sale_base_act_date  := l_cst_rsurcs_data_rec.rsv_sale_base_act_date;     -- �\�񔄏㋒�_�L���J�n��
      l_get_data_rec.rsv_sale_base_code      := l_cst_rsurcs_data_rec.rsv_sale_base_code;         -- �\�񔄏㋒�_
      l_get_data_rec.route_no                := l_cst_rsurcs_data_rec.route_no;                   -- ���[�gNo
      l_get_data_rec.employee_number         := l_cst_rsurcs_data_rec.employee_number;            -- �S���c�ƈ�CD
      l_get_data_rec.full_name               := l_cst_rsurcs_data_rec.full_name;                  -- �S���c�ƈ���
      l_get_data_rec.start_date_active       := l_cst_rsurcs_data_rec.start_date_active;          -- �S���c�ƈ��J�n��
      l_get_data_rec.end_date_active         := l_cst_rsurcs_data_rec.end_date_active;            -- �S���c�ƈ��I����
--
      -- ========================================
      -- A-3.�o�̓t�@�C���ւ̃f�[�^�o��
      -- ========================================
      output_csv_rec(
        i_cst_rsurcs_dt_rec  =>  l_get_data_rec        -- �S���c�ƈ��f�[�^
       ,iv_base_code         =>  lv_base_code          -- ���_�R�[�h
       ,id_standard_date     =>  ld_standard_date      -- ����t
       ,ov_errbuf            =>  lv_errbuf             -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>  lv_retcode            -- ���^�[���E�R�[�h
       ,ov_errmsg            =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP get_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_cst_rsurcs_data_cur;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome start
    IF (gn_target_cnt = 0) THEN
      ov_errbuf := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
       );
--
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
--
      ov_retcode := cv_status_warn;
    END IF;
    -- 2011-03-15 Ver1.1 Add Naoki.Horigome end
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_cst_rsurcs_data_cur%ISOPEN) THEN
        CLOSE get_cst_rsurcs_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf              OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode             OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
    ,iv_base_code        IN         VARCHAR2     -- ���_�R�[�h
    ,iv_standard_date    IN         VARCHAR2     -- ���(1�F���� / 2�F����)
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I��
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_whick_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code      => iv_base_code       -- ���_�R�[�h
      ,iv_standard_date  => iv_standard_date   -- ���(1�F���� / 2�F����)
      ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-4.�I������
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
--                   );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO019A11C;
/
