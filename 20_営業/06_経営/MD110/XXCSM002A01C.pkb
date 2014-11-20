CREATE OR REPLACE PACKAGE BODY XXCSM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A01C(body)
 * Description      : ���i�v��p�ߔN�x�̔����яW�v
 * MD.050           : ���i�v��p�ߔN�x�̔����яW�v MD050_CSM_002_A01
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  lock_plan_result            ���i�v�斾�׃e�[�u�������f�[�^���b�N(A-12)
 *  delete_plan_result          ���i�v�斾�׃e�[�u�������f�[�^�폜(A-12)
 *  insert_plan_result          �f�[�^�o�^(A-12)
 *  year_data_select            ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(A-8)
 *  obj_month_data_select       ���f�[�^�쐬(�Ώی��̃f�[�^���o)(A-8)
 *  temp_2months_data           ���f�[�^�쐬(����2�������f�[�^���g���ꍇ)(A-8)
 *  temp_data_make              ���f�[�^�쐬(A-8)
 *  sales_result_select         �̔����ђ��o����(A-2)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   S.Son            �V�K�쐬
 *  2009/02/23    1.1   SCS S.Son       [��QCT_057] �����f�[�^���폜�����s��Ή�
 *  2009/03/03    1.2   M.Ohtsuki       [��QCT_074] ���O�Əo�͂̕\���̕s��v�̑Ή�
 *  2009/03/04    1.3   S.Son           [��QCT_075] �l���p�i�ڕs��̑Ή�
 *  2009/03/18    1.4   S.Son            �d�l�ύX�Ή�
 *  2009/05/01    1.5   M.Ohtsuki       [��QT1_0861] ����i�ڂ̏����Ώۏ��O 
 *  2009/06/03    1.6   M.Ohtsuki       [��QT1_1174] �Z���^�[�[�i�̕s��̑Ή� 
 *  2009/08/03    1.7   T.Tsukino       [��Q�Ǘ��ԍ�0000479]���\���P�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; --�^�p��
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  --
  cv_xxcsm                  CONSTANT VARCHAR2(100) := 'XXCSM'; 
  --���b�Z�[�W�[�R�[�h
  cv_chk_err_00004          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';       --�\�Z�N�x�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00005          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';       --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_chk_err_00006          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';       --�N�Ԕ̔��v��J�����_�[�����݃G���[���b�Z�[�W
  cv_msg_00048              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00048';       --�R���J�����g���̓p�����[�^���b�Z�[�W(���_�R�[�h)
  cv_chk_err_00053          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00053';       --�i�ڃ}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_chk_err_00085          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00085';       --�Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_chk_err_00095          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00095';       --���i�v��p�̔����уe�[�u�����b�N�G���[
  cv_chk_err_00110          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00110';       --�������擾�G���[
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';       --�z��O�G���[���b�Z�[�W
  cv_msg_00112              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00112';       --�R���J�����g���̓p�����[�^���b�Z�[�W(�p�������ԍ�)
  cv_msg_00113              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00113';       --�R���J�����g���̓p�����[�^���b�Z�[�W(�p��������)
  cv_chk_err_00114          CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00114';       --���̓p�����[�^�s�����b�Z�[�W
  cv_msg_00116              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00116';       --�R���J�����g���̓p�����[�^���b�Z�[�W(�i�ڃR�[�h)
  --�g�[�N��
  cv_tkn_cd_colmun          CONSTANT VARCHAR2(100) := 'COLMUN';                 --�e�[�u����
  cv_tkn_cd_prof            CONSTANT VARCHAR2(100) := 'PROF_NAME';              --�J�X�^���E�v���t�@�C���E�I�v�V�����̉p��
  cv_tkn_cd_item            CONSTANT VARCHAR2(100) := 'ITEM';                   --�K�v�ɉ������e�L�X�g����
  cv_tkn_cd_year            CONSTANT VARCHAR2(100) := 'YYYY';                   --�\�Z�N�x
  cv_tkn_cd_item_cd         CONSTANT VARCHAR2(100) := 'ITEM_CD';                --�i�ڃR�[�h
  cv_tkn_cd_parallel_no     CONSTANT VARCHAR2(100) := 'PARALLEL_NO';            --�p�������ԍ�
  cv_tkn_cd_parallel_cnt    CONSTANT VARCHAR2(100) := 'PARALLEL_CNT';           --�p��������
  cv_tkn_cd_deal            CONSTANT VARCHAR2(100) := 'DEAL_CD';                --���i�Q�R�[�h
  cv_tkn_cd_kyoten          CONSTANT VARCHAR2(100) := 'KYOTEN_CD';              --���_�R�[�h
  cv_tkn_year_month         CONSTANT VARCHAR2(100) := 'YYYYMM';                 --�N��
  --
  cv_language_ja            CONSTANT VARCHAR2(2)   := USERENV('LANG');           --����(���{��)
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                       --�t���OY
--
--//+ADD START 2009/08/03 0000479 T.Tsukino
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';
  cv_lookup_type_01         CONSTANT VARCHAR2(30)  := 'XXCSM1_SUM_PASS_SALES_THREAD'; -- ���i�v��p�ߔN�x�̔����яW�v�p���������X�g
  cv_lookup_type_02         CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';             -- �i�ڃX�e�[�^�X���X�g
  cn_inv_application_id     CONSTANT NUMBER        := 401;                            -- �A�v���P�[�V����ID�iINV�j
  cv_id_flex_code_mcat      CONSTANT VARCHAR2(30)  := 'MCAT';                         -- KFF�R�[�h�i�i�ڃJ�e�S���j
  cv_id_flex_str_code_sgum  CONSTANT VARCHAR2(30)  := 'XXCMN_SGUN_CODE';              -- �̌n�R�[�h�i����Q�j
--//+ADD END 2009/08/03 0000479 T.Tsukino
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
--
  calendar_check_expt           EXCEPTION;     --�J�����_�[�`�F�b�N�G���[
  no_date_expt                  EXCEPTION;     -- �Ώۃf�[�^�Ȃ��G���[
  parameter_expt                EXCEPTION;     --�p�����[�^�`�F�b�N�G���[
  check_lock_expt               EXCEPTION;     --�e�[�u�����b�N�G���[
  item_skip_expt                EXCEPTION;     --�i�ڒP�ʂŃX�L�b�v�G���[
  group_cd_expt                 EXCEPTION;     --���i�Q�R�[�h�擾��O
  temp_skip_expt                EXCEPTION;     --���f�[�^�쐬��O
  no_data_skip_expt             EXCEPTION;     --���f�[�^�쐬�X�L�b�v

  PRAGMA EXCEPTION_INIT(check_lock_expt,-54);   --���b�N�擾�ł��Ȃ��G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCSM002A01C';             -- �p�b�P�[�W��
  gv_calendar_profile  CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER'; --�N�Ԕ̔��v��J�����_�[�v���t�@�C����
  gv_bks_profile       CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';         --GL��v����ID�v���t�@�C����
--//ADD START 2009/03/04 CT_075 S.Son
  gv_disc_group_cd     CONSTANT VARCHAR2(100) := 'XXCSM1_DISCOUNT_GROUP4_CD';--�l�����p�i�ڐ���Q�R�[�h�v���t�@�C����
--//ADD END   2009/03/04 CT_075 S.Son
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_calendar_name         VARCHAR2(100);                                --�N�Ԕ̔��v��J�����_�[��
  gv_parallel_value_no     VARCHAR2(100);                                --���̓p�����[�^�p�������ԍ�
--//+DEL START 2009/08/03 0000479 T.Tsukino
--  gv_parallel_cnt          VARCHAR2(100);                                --���̓p�����[�^�p��������
--//+DEL END 2009/08/03 0000479 T.Tsukino
  gv_location_cd           VARCHAR2(4);                                  --���̓p�����[�^���_�R�[�h
  gv_item_no               VARCHAR2(32);                                 --���̓p�����[�^�i�ڃR�[�h
  gv_bks_id                NUMBER;                                       --��v����ID
  gt_active_year           xxcsm_item_plan_headers.plan_year%TYPE;       --�Ώ۔N�x
  gt_start_date            gl_periods.start_date%TYPE;                   --�\�Z�N�x�J�n��
  gn_temp_normal_cnt       NUMBER;                                       -- ���f�[�^�쐬���팏��
  gn_temp_error_cnt        NUMBER;                                       -- ���f�[�^�쐬�G���[����
--//ADD START 2009/03/04 CT_075 S.Son
  gv_discount_cd           VARCHAR2(10);         --�l�����p�i�ڐ���Q�R�[�h�v���t�@�C����
--//ADD END   2009/03/04 CT_075 S.Son
--  
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';            -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_carender_cnt   NUMBER;          --�N�Ԕ̔��v��J�����_�[�擾��
    lv_tkn_value      VARCHAR2(4000);  --�g�[�N���l
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_parallel_value_no CONSTANT NUMBER      := 0;
--
    -- *** ���[�J���ϐ� ***
--
    ln_retcode           NUMBER;            -- �N�Ԕ̔��v��J�����_�[���^�[���R�[�h
    lv_result            VARCHAR2(100);     -- �N�Ԕ̔��v��J�����_�[�L���N�x��������(0:�L���N�x1�̏ꍇ�A1:�L���N�x�������܂���0�̏ꍇ)
    ln_cnt               NUMBER;            -- �J�E���^
    lv_pram_op_1         VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(�p�������ԍ�)
    lv_pram_op_2         VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(�p��������)
    lv_pram_op_3         VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(���_�R�[�h)
    lv_pram_op_4         VARCHAR2(100);     -- �p�����[�^���b�Z�[�W�o��(�i�ڃR�[�h)
    -- *** ���[�J���E�J�[�\�� ***
--
      /**      �N�x�J�n���擾       **/
    CURSOR startdate_cur1
    IS
      SELECT  gp.start_date
      FROM    gl_sets_of_books gsob
             ,gl_periods gp
      WHERE   gsob.set_of_books_id = gv_bks_id
      AND     gsob.period_set_name = gp.period_set_name
      AND     gp.period_year = gt_active_year
      AND     gp.period_num = 1
      ;
    startdate_cur1_rec startdate_cur1%ROWTYPE;
    
    CURSOR startdate_cur2
    IS
      SELECT  TO_DATE(gt_active_year||TO_CHAR(gp.start_date,'MMDD'),'YYYYMMDD') start_date
      FROM    gl_periods gp
             ,(SELECT  gp.period_year period_year
                      ,gp.period_set_name period_set_name
               FROM    gl_periods gp
                      ,gl_sets_of_books gsob
               WHERE   gsob.set_of_books_id = gv_bks_id
               AND     gsob.period_set_name = gp.period_set_name
               AND     gp.start_date <= cd_process_date
               AND     gp.end_date   >= cd_process_date
              ) year_view
      WHERE   gp.period_num = 1
      AND     gp.period_year = year_view.period_year
      AND     year_view.period_set_name = gp.period_set_name
      ;
      startdate_cur2_rec startdate_cur2%ROWTYPE;
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    /** �ڋq�R�[�h���o **/
--    CURSOR cust_select_cur
--    IS
--      SELECT hca.account_number
--      FROM   hz_cust_accounts    hca
--      WHERE  hca.customer_class_code = '1'
--      ORDER  BY hca.account_number
--      ;
--    TYPE cust_tbl_type IS TABLE OF cust_select_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--    cust_tbl  cust_tbl_type;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--���[�J���ϐ�������
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--�@���̓p�����[�^�����b�Z�[�W�o��
    --�p�������ԍ�
    lv_pram_op_1 := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_msg_00112
                                            ,iv_token_name1  => cv_tkn_cd_parallel_no
                                            ,iv_token_value1 => gv_parallel_value_no
                                            );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_1);
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    --�p��������
--    lv_pram_op_2 := xxccp_common_pkg.get_msg(
--                                            iv_application  => cv_xxcsm
--                                           ,iv_name         => cv_msg_00113
--                                           ,iv_token_name1  => cv_tkn_cd_parallel_cnt
--                                           ,iv_token_value1 => gv_parallel_cnt
--                                           );
--    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_2);
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_2);
--//+DEL END 2009/08/03 0000479 T.Tsukino
    --���_�R�[�h
    lv_pram_op_3 := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_msg_00048
                                           ,iv_token_name1  => cv_tkn_cd_kyoten
                                           ,iv_token_value1 => gv_location_cd
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_3);
    --�i�ڃR�[�h
    lv_pram_op_4 := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_msg_00116
                                           ,iv_token_name1  => cv_tkn_cd_item_cd
                                           ,iv_token_value1 => gv_item_no
                                           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_pram_op_4);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_pram_op_4);
--�A���̓p�����[�^�`�F�b�N
--//+UPD START 2009/08/03 0000479 T.Tsukino
--    IF (gv_parallel_value_no IS NULL) AND (gv_parallel_cnt IS NOT NULL) THEN
    IF (gv_parallel_value_no IS NULL) THEN
      IF(gv_location_cd IS NULL) AND (gv_item_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00114
                                             );
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
--    ELSIF (gv_parallel_value_no IS NOT NULL) AND (gv_parallel_cnt IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                                              iv_application  => cv_xxcsm
--                                             ,iv_name         => cv_chk_err_00114
--                                             );
--      lv_errbuf := lv_errmsg;
--      RAISE parameter_expt;
--    ELSIF (gv_parallel_value_no >= gv_parallel_cnt) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                                              iv_application  => cv_xxcsm
--                                             ,iv_name         => cv_chk_err_00114
--                                             );
--      lv_errbuf := lv_errmsg;
--      RAISE parameter_expt;
      END IF;
      gv_parallel_value_no := cv_parallel_value_no;
      INSERT INTO xxcsm_tmp_cust_accounts(
        cust_account_id
       ,account_number
      )
      SELECT  TO_NUMBER(gv_parallel_value_no)
             ,xabv.base_code
      FROM   xxcso_aff_base_v2	     xabv
      WHERE  xabv.summary_flag  = cv_flg_n
      ;
    ELSIF (gv_parallel_value_no IS NOT NULL) THEN
      INSERT INTO xxcsm_tmp_cust_accounts(
        cust_account_id
       ,account_number
      )
      SELECT  TO_NUMBER(gv_parallel_value_no)
             ,xabv.base_code
      FROM    fnd_lookup_values_vl  flvv
             ,xxcso_aff_base_v2     xabv
      WHERE   flvv.lookup_type   = cv_lookup_type_01
        AND   flvv.enabled_flag  = cv_flg_y
        AND   cd_process_date    BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                     AND NVL(flvv.end_date_active,cd_process_date)
        AND   flvv.attribute1    = gv_parallel_value_no
        AND   xabv.base_code     = flvv.lookup_code
        AND   xabv.summary_flag  = cv_flg_n
      UNION ALL
      SELECT  TO_NUMBER(gv_parallel_value_no)
             ,xablv.child_base_code
      FROM    xxcso_aff_base_level_v2  xablv
             ,xxcso_aff_base_v2        xabv
      WHERE   xabv.base_code     = xablv.child_base_code
        AND   xabv.summary_flag  = cv_flg_n
      START WITH
              xablv.base_code IN
              (
               SELECT  flvv.lookup_code
               FROM    fnd_lookup_values_vl  flvv
               WHERE   flvv.lookup_type   = cv_lookup_type_01
                 AND   flvv.enabled_flag  = cv_flg_y
                 AND   cd_process_date    BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                              AND NVL(flvv.end_date_active,cd_process_date)
                 AND   flvv.attribute1    = gv_parallel_value_no
              )
      CONNECT BY PRIOR
              xablv.child_base_code = xablv.base_code
      ;
    END IF;
--//+UPD END 2009/08/03 0000479 T.Tsukino
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    IF (gv_parallel_value_no IS NULL) AND (gv_parallel_cnt IS NULL) THEN
--      gv_parallel_value_no := 0;
--      gv_parallel_cnt := 1;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--    END IF;
--�B �v���t�@�C���l�擾
    --�N�Ԕ̔��v��J�����_�[���擾
    gv_calendar_name := FND_PROFILE.VALUE(gv_calendar_profile);
    IF gv_calendar_name IS NULL THEN
        lv_tkn_value := gv_calendar_profile;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00005
                                             ,iv_token_name1  => cv_tkn_cd_prof
                                             ,iv_token_value1 => lv_tkn_value
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --��v����ID�擾
    gv_bks_id := FND_PROFILE.VALUE(gv_bks_profile);
    IF gv_bks_id IS NULL THEN
       lv_tkn_value := gv_bks_profile;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--//ADD START 2009/03/04 CT_075 S.Son
    --�l�����p�i�ڐ���Q�R�[�h�擾
    gv_discount_cd := FND_PROFILE.VALUE(gv_disc_group_cd);
    IF (gv_discount_cd IS NULL) THEN
       lv_tkn_value := gv_disc_group_cd;
       lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00005
                                            ,iv_token_name1  => cv_tkn_cd_prof
                                            ,iv_token_value1 => lv_tkn_value
                                            );
       lv_errbuf := lv_errmsg;
       RAISE global_api_expt;
    END IF;
--//ADD END   2009/03/04 CT_075 S.Son
--�C �N�Ԕ̔��v��J�����_�[���݃`�F�b�N
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_carender_cnt
      FROM    fnd_flex_value_sets  ffv                                      -- �l�Z�b�g�w�b�_
      WHERE   ffv.flex_value_set_name = gv_calendar_name;                   -- �N�Ԕ̔��J�����_�[��      
      IF (ln_carender_cnt = 0) THEN                                         -- �J�����_�[���݌�����0���̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_xxcsm
                                             ,iv_name         => cv_chk_err_00006
                                             ,iv_token_name1  => cv_tkn_cd_item
                                             ,iv_token_value1 => gv_calendar_name
                                             );
        lv_errbuf := lv_errmsg;
        RAISE calendar_check_expt;
      END IF;  
    END;
--//+UPD START 2009/08/03 0000479 T.Tsukino
--�D �N�Ԕ̔��v��J�����_�[�L���N�x�擾
    xxcsm_common_pkg.get_yearplan_calender(
--                                           id_comparison_date  => cd_creation_date
--��������������������������������������������������������������������������������������������������������������������������������
                                           id_comparison_date  => cd_process_date  -- �Ɩ����t
--//+UPD END 2009/08/03 0000479 T.Tsukino                                           
                                          ,ov_status           => lv_result
                                          ,on_active_year      => gt_active_year
                                          ,ov_retcode          => ln_retcode
                                          ,ov_errbuf           => lv_errbuf
                                          ,ov_errmsg           => lv_errmsg
                                          );
    IF (ln_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_xxcsm
                                           ,iv_name         => cv_chk_err_00004
                                           ,iv_token_name1  => cv_tkn_cd_item
                                           ,iv_token_value1 => gv_calendar_name
                                           );
--//+ADD START 2009/03/03 CT074 M.Ohtsuki
      lv_errbuf := lv_errmsg;
--//+ADD END   2009/03/03 CT074 M.Ohtsuki
      RAISE global_api_expt;
    END IF;
--�F �\�Z�쐬�N�x�̔N�x�J�n�����擾
    OPEN startdate_cur1;
      FETCH startdate_cur1 INTO startdate_cur1_rec;
      IF startdate_cur1%NOTFOUND THEN
        OPEN startdate_cur2;
          FETCH startdate_cur2 INTO startdate_cur2_rec;
          gt_start_date := startdate_cur2_rec.start_date;
        CLOSE startdate_cur2;
      ELSE
        gt_start_date := startdate_cur1_rec.start_date;
      END IF;
    CLOSE startdate_cur1;
--//+DEL START 2009/08/03 0000479 T.Tsukino
--�G �ڋq�R�[�h���o
--    OPEN cust_select_cur;
--      FETCH cust_select_cur BULK COLLECT INTO cust_tbl;
--      FOR i IN 1..cust_tbl.COUNT LOOP
--        INSERT INTO xxcsm_tmp_cust_accounts(
--          cust_account_id
--         ,account_number
--        )
--        VALUES(
--//+UPD START 2009/02/26 CT057 S.Son
--        --i
--          MOD(i,TO_NUMBER(gv_parallel_cnt)) 
----//+UPD END 2009/02/26 CT057 S.Son
--         ,cust_tbl(i).account_number
--        );
--      END LOOP;
--    CLOSE cust_select_cur;
--//+DEL END 2009/08/03 0000479 T.Tsukino
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** ���̓p�����[�^�`�F�b�N��O���� ***
    WHEN parameter_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** �N�Ԕ̔��v��J�����_�[�����ݗ�O���� ***
    WHEN calendar_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : lock_plan_result
   * Description      : ���i�v�斾�׃e�[�u�������f�[�^���b�N(A-12)
   ***********************************************************************************/
  PROCEDURE lock_plan_result(
    iv_location_cd      IN   VARCHAR2,                        -- ���_�R�[�h
    iv_item_no          IN   VARCHAR2,                        --�i�ڃR�[�h
    ov_errbuf           OUT  NOCOPY VARCHAR2,                 -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                 -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_plan_result'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_plan_result_cur 
    IS
      SELECT xipr.location_cd                              --���_�R�[�h
            ,xipr.subject_year                             --�Ώ۔N�x
      FROM   xxcsm_item_plan_result xipr                   --���i�v��p�̔�����
      WHERE  xipr.location_cd = iv_location_cd             --���_�R�[�h
      AND    xipr.item_no = iv_item_no                     --�i�ڃR�[�h
      AND    xipr.subject_year >= (gt_active_year - 2)
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���b�N�擾����
    OPEN lock_plan_result_cur;
    CLOSE lock_plan_result_cur;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN check_lock_expt THEN
      IF lock_plan_result_cur%ISOPEN THEN
        CLOSE lock_plan_result_cur;
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  =>  cv_xxcsm
                                   ,iv_name         =>  cv_chk_err_00095
                                   ,iv_token_name1  => cv_tkn_cd_kyoten
                                   ,iv_token_value1 => iv_location_cd
                                   ,iv_token_name2  => cv_tkn_cd_item_cd
                                   ,iv_token_value2 => iv_item_no
                                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END lock_plan_result;
  
  /***********************************************************************************
   * Procedure Name   : delete_plan_result
   * Description      : ���i�v�斾�׃e�[�u�������f�[�^�폜(A-12)
   ***********************************************************************************/
  PROCEDURE delete_plan_result(
    iv_location_cd      IN   VARCHAR2,                       -- ���i�v��w�b�_ID
    iv_item_no          IN   VARCHAR2,                       --�i�ڃR�[�h
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_plan_result'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �폜����
    DELETE xxcsm_item_plan_result xipr                         --���i�v��p�̔����уe�[�u��
    WHERE  xipr.location_cd = iv_location_cd                   --���_�R�[�h
    AND    xipr.item_no = iv_item_no                           --�i�ڃR�[�h
    AND    xipr.subject_year >= (gt_active_year - 2);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END delete_plan_result;
--
  /**********************************************************************************
   * Procedure Name   : insert_plan_result
   * Description      : �f�[�^�o�^(A-12)
   ***********************************************************************************/
  PROCEDURE insert_plan_result(
     in_subject_year           IN  NUMBER                       -- �Ώ۔N�x
    ,in_year_month             IN  NUMBER                       -- �N��
    ,in_month_no               IN  NUMBER                       -- ��
    ,iv_location_cd            IN  VARCHAR2                     -- ���_�R�[�h
    ,iv_item_no                IN  VARCHAR2                     -- ���i�R�[�h
    ,iv_item_group_no          IN  VARCHAR2                     -- ���i�Q�R�[
    ,in_amount                 IN  NUMBER                       -- ����
    ,in_sales_budget           IN  NUMBER                       -- ������z
    ,in_amount_gross_margin    IN  NUMBER                       -- �e���v
    ,ov_errbuf                 OUT NOCOPY VARCHAR2              -- �G���[�E���b�Z�[�W
    ,ov_retcode                OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h
    ,ov_errmsg                 OUT NOCOPY VARCHAR2)             -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_plan_result'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�^����
      INSERT INTO xxcsm_item_plan_result xipr(    -- ���i�v��p�̔����уe�[�u��
         xipr.subject_year                        -- �Ώ۔N�x
        ,xipr.year_month                          -- �N��
        ,xipr.month_no                            -- ��
        ,xipr.location_cd                         -- ���_�R�[�h
        ,xipr.item_no                             -- ���i�R�[�h
        ,xipr.item_group_no                       -- ���i�Q�R�[�h
        ,xipr.amount                              -- ����
        ,xipr.sales_budget                        -- ������z
        ,xipr.amount_gross_margin                 -- �e���v
        ,xipr.created_by                          -- �쐬��
        ,xipr.creation_date                       -- �쐬��
        ,xipr.last_updated_by                     -- �ŏI�X�V��
        ,xipr.last_update_date                    -- �ŏI�X�V��
        ,xipr.last_update_login                   -- �ŏI�X�V���O�C��
        ,xipr.request_id                          -- �v��ID
        ,xipr.program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xipr.program_id                          -- �R���J�����g�E�v���O����ID
        ,xipr.program_update_date)                -- �v���O�����X�V��
      VALUES(
         in_subject_year                          -- �Ώ۔N�x
        ,in_year_month                            -- �N��
        ,in_month_no                              -- ��
        ,iv_location_cd                           -- ���_�R�[�h
        ,iv_item_no                               -- ���i�R�[�h
        ,iv_item_group_no                         -- ���i�Q�R�[�h
        ,in_amount                                -- ����
        ,in_sales_budget                          -- ������z
        ,in_amount_gross_margin                   -- �e���v
        ,cn_created_by                            -- �쐬��
        ,cd_creation_date                         -- �쐬��
        ,cn_last_updated_by                       -- �ŏI�X�V��
        ,cd_last_update_date                      -- �ŏI�X�V��
        ,cn_last_update_login                     -- �ŏI�X�V���O�C��
        ,cn_request_id                            -- �v��ID
        ,cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P
        ,cn_program_id                            -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date                   -- �v���O�����X�V��
        );
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_plan_result;
--
  /***********************************************************************************
   * Procedure Name   : year_data_select
   * Description      : ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(A-8)
   ***********************************************************************************/
  PROCEDURE year_data_select(
    iv_location_cd      IN   VARCHAR2,                       --���_�R�[�h
    iv_item_no          IN   VARCHAR2,                       --�i�ڃR�[�h
    in_start_yyyymm     IN   NUMBER,                         --�J�n�N��
    in_end_yyyymm       IN   NUMBER,                         --�I���N��
    on_amount           OUT  NUMBER,                         --�Ώ۔N�x�N�Ԑ��ʌv
    on_sales_budget     OUT  NUMBER,                         --�Ώ۔N�x�N�Ԕ���v
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'year_data_select'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
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
    CURSOR year_amount_cur
    IS
      SELECT  SUM(xipr.amount)         amount                 --�Ώ۔N�x���ʔN�Ԍv
             ,SUM(xipr.sales_budget)   sales_budget           --�Ώ۔N�x����N�Ԍv
      FROM    xxcsm_item_plan_result  xipr                    --���i�v��p�̔����уe�[�u��
      WHERE   xipr.location_cd = iv_location_cd               --���_�R�[�h
      AND     xipr.item_no = iv_item_no                       --�i�ڃR�[�h
      AND     (xipr.year_month >= in_start_yyyymm             --�N��
              AND xipr.year_month < in_end_yyyymm)
    ;
    year_amount_cur_rec year_amount_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    --���[�J���ϐ�������
    
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN year_amount_cur;
      FETCH year_amount_cur INTO year_amount_cur_rec;
      on_amount := year_amount_cur_rec.amount;                  --���ʔN�Ԍv
      on_sales_budget := year_amount_cur_rec.sales_budget;      --����N�Ԍv
    CLOSE year_amount_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END year_data_select;
--
  /***********************************************************************************
   * Procedure Name   : obj_month_data_select
   * Description      : ���f�[�^�쐬(�Ώی��̃f�[�^���o)(A-8)
   ***********************************************************************************/
  PROCEDURE obj_month_data_select(
    iv_location_cd      IN   VARCHAR2,                       --���_�R�[�h
    iv_item_no          IN   VARCHAR2,                       --�i�ڃR�[�h
    in_year             IN   NUMBER,                         --�Ώ۔N
    in_month            IN   NUMBER,                         --�Ώی�
    on_amount           OUT  NUMBER,                         --�Ώ۔N������
    on_sales_budget     OUT  NUMBER,                         --�Ώ۔N������
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'obj_month_data_select'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
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
    CURSOR obj_month_amount_cur
    IS
      SELECT  xipr.amount                 --�Ώ۔N�x���ʔN�Ԍv
             ,xipr.sales_budget           --�Ώ۔N�x����N�Ԍv
      FROM    xxcsm_item_plan_result  xipr                    --���i�v��p�̔����уe�[�u��
      WHERE   xipr.location_cd = iv_location_cd               --���_�R�[�h
      AND     xipr.item_no = iv_item_no                       --�i�ڃR�[�h
      AND     xipr.subject_year = in_year                     --�N�x
      AND     xipr.month_no    = in_month                     --��
    ;
    obj_month_amount_cur_rec obj_month_amount_cur%ROWTYPE;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    --���[�J���ϐ�������
    
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN obj_month_amount_cur;
      FETCH obj_month_amount_cur INTO obj_month_amount_cur_rec;
      on_amount       := obj_month_amount_cur_rec.amount;                  --���ʔN�Ԍv
      on_sales_budget := obj_month_amount_cur_rec.sales_budget;            --����N�Ԍv
    CLOSE obj_month_amount_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END obj_month_data_select;
--
  /***********************************************************************************
   * Procedure Name   : temp_2months_data
   * Description      : ���f�[�^�쐬(����2�������̃f�[�^���g���ꍇ)(A-8)
   ***********************************************************************************/
  PROCEDURE temp_2months_data(
    iv_location_cd      IN   VARCHAR2,                       --���_�R�[�h
    iv_item_no          IN   VARCHAR2,                       --�i�ڃR�[�h
    in_discrete_cost    IN   NUMBER,                         --�c�ƌ���
    on_amount           OUT  NUMBER,                         --����
    on_sales_budget     OUT  NUMBER,                         --����
    on_margin           OUT  NUMBER,                         --�e���v
    ov_errbuf           OUT  NOCOPY VARCHAR2,                --�G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                --���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                --���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'temp_2months_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lv_location_cd                 VARCHAR2(9);           --���_�R�[�h
    lv_item_no                     VARCHAR2(32);          --�i�ڃR�[�h
    ln_discrete_cost               NUMBER;                --�c�ƌ���
    ln_start_yyyymm                NUMBER;                --����2�������f�[�^�W�v�J�n��
    ln_end_yyyymm                  NUMBER;                --����2�������f�[�^�W�v�I����
    ln_near_2months_amount         NUMBER;                --����2�������f�[�^���ʏW�v
    ln_near_2months_budget         NUMBER;                --����2�������f�[�^����W�v
    ln_year_average_amount         NUMBER;                --���ʔN�ԕ���
    ln_year_average_budget         NUMBER;                --����N�ԕ���
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    --���[�J���ϐ�������
    lv_location_cd        := iv_location_cd;           --���_�R�[�h
    lv_item_no            := iv_item_no;               --�i�ڃR�[�h
    ln_discrete_cost      := in_discrete_cost;         --�c�ƌ���
    on_amount             := NULL;                     --����
    on_sales_budget       := NULL;                     --����
    on_margin             := NULL;                     --�e���v
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--����2�������̃f�[�^���擾
    ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-2),'YYYYMM'));
    ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
    -- ==================================================
    -- ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(�O�N�x)(A-8)
    -- ����2�������̃f�[�^�W�v
    -- ==================================================
    year_data_select(
                    lv_location_cd                   --���_�R�[�h
                   ,lv_item_no                       --�i�ڃR�[�h
                   ,ln_start_yyyymm                  --�J�n�N��
                   ,ln_end_yyyymm                    --�I���N��
                   ,ln_near_2months_amount           --�O�N�x�N�Ԑ��ʌv
                   ,ln_near_2months_budget           --�O�N�x�N�Ԕ���v
                   ,lv_errbuf                        --�G���[�E���b�Z�[�W
                   ,lv_retcode                       --���^�[���E�R�[�h
                   ,lv_errmsg                        --���[�U�[�E�G���[�E���b�Z�[�W
                  );
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_others_expt;
    END IF;
    --���ʔN�ԕ��ς��Z�o
    ln_year_average_amount := ln_near_2months_amount/2;
    --����N�ԕ��ς��Z�o
    ln_year_average_budget := ln_near_2months_budget/2;
    --���f�[�^�̔�����Z�o
    on_sales_budget := ROUND(ln_year_average_budget,0);
    --���f�[�^�̐��ʂ��Z�o
    on_amount := ROUND(ln_year_average_amount,0);
    --���f�[�^�̑e���v���Z�o
    on_margin := ROUND((on_sales_budget - (on_amount * ln_discrete_cost)),0);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END temp_2months_data;
--
  /***********************************************************************************
   * Procedure Name   : temp_data_make
   * Description      : ���f�[�^�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE temp_data_make(
    iv_location         IN  VARCHAR2,                          -- �O���_�R�[�h
    iv_item_no          IN  VARCHAR2,                          -- �O�i�ڃR�[�h
    iv_group_cd         IN  VARCHAR2,                          -- �O���i�Q�R�[�h
    iv_sales_start      IN  VARCHAR2,                          -- �O������
    in_discrete_cost    IN  NUMBER,                            -- �O�c�ƌ���
    ov_errbuf           OUT  NOCOPY VARCHAR2,                  -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                  -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'temp_data_make'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_subject_year                NUMBER;               --���f�[�^�쐬�Ώ۔N�x
    ln_year_month                  NUMBER;               --���f�[�^�쐬�N��
    ln_month_no                    NUMBER;               --���f�[�^�쐬��
    lv_location_cd                 VARCHAR2(4);          --���f�[�^�쐬���_�R�[�h
    lv_group_cd                    VARCHAR2(4);          --���f�[�^�쐬���i�Q�R�[�h
    lv_item_no                     VARCHAR2(32);         --���f�[�^�쐬�i�ڃR�[�h
    ln_amount                      NUMBER;               --���f�[�^�쐬����
    ln_sales_budget                NUMBER;               --���f�[�^�쐬����
    ln_margin                      NUMBER;               --���f�[�^�쐬�e���v
    ln_months                      NUMBER;               --�R���J�����g�N�����t����A�\�Z�N�x�J�n���܂ł̌���
    ln_start_months                NUMBER;               --����������A�\�Z�N�x�J�n���܂ł̌���
    ln_process_months              NUMBER;               --����������A�R���J�����g�N���܂ł̌���
    ln_start_yyyymm                NUMBER;               --�N�ԏW�v�J�n��
    ln_end_yyyymm                  NUMBER;               --�N�ԏW�v�I����
    ld_sales_start                 DATE;                 --������
    ln_befor_last_year_amount      NUMBER;               --�O�X�N�x���ʔN�Ԍv
    ln_befor_last_year_budget      NUMBER;               --�O�X�N�x����N�Ԍv
    ln_last_year_amount            NUMBER;               --�O�N�x���ʔN�Ԍv
    ln_last_year_budget            NUMBER;               --�O�N�x����N�Ԍv
    ln_obj_year                    NUMBER;               --���f�[�^�쐬�p�Ώ۔N
    ln_obj_month                   NUMBER;               --���f�[�^�쐬�p�Ώی�
    ln_obj_amount                  NUMBER;               --���f�[�^�쐬�p�Ώی�����
    ln_obj_sales_budget            NUMBER;               --���f�[�^�쐬�p�Ώی�����
    ln_discrete_cost               NUMBER;               --���f�[�^�쐬�p�c�ƌ���
    ln_result_budget_rate          NUMBER;               --������є䗦
    ln_result_amount_rate          NUMBER;               --���ʎ��є䗦
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
--���[�J���ϐ�������
    lv_location_cd     := iv_location;                                --���_�R�[�h
    lv_item_no         := iv_item_no;                                 --�i�ڃR�[�h
    lv_group_cd        := iv_group_cd;                                --���i�Q�R�[�h
    ld_sales_start     := TO_DATE(iv_sales_start,'YYYY-MM-DD');       --������
    ln_discrete_cost   := in_discrete_cost;                           --�c�ƌ���
    ln_subject_year    := gt_active_year - 1;                         --�Ώ۔N�x
    ln_obj_year        := gt_active_year - 2;                         --�Ώی��f�[�^�擾�Ώ۔N�x
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�R���J�����g�N�����t����A�\�Z�N�x�J�n���܂ł̌����Z�o
    ln_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(cd_process_date,'YYYYMM')||'01','YYYYMMDD'));
    --����������A�\�Z�N�x�J�n���܂ł̌����B(���ё��݌���)
    ln_start_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(gt_start_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(ld_sales_start,'YYYYMM')||'01','YYYYMMDD'));
    --����������A�R���J�����g�N���܂ł̌���
    ln_process_months := MONTHS_BETWEEN(TO_DATE(TO_CHAR(cd_process_date,'YYYYMM')||'01','YYYYMMDD'),
                                TO_DATE(TO_CHAR(ld_sales_start,'YYYYMM')||'01','YYYYMMDD'));
    --�������J��Ԃ�
    FOR j IN 0..ln_months LOOP
      EXIT WHEN j = ln_months;
      BEGIN
        --���f�[�^�̔N�����Z�o
        ln_year_month := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,j),'YYYYMM'));
        --���f�[�^�̌����Z�o
        ln_month_no := SUBSTR(ln_year_month,5,2);
        --1�D�������i(�����N���͗\�Z�N�x�J�n�N������27�����O�̃f�[�^)�̉��f�[�^�쐬
        IF ln_start_months >= 27 THEN
          --�O�X�N�x�̎��ђ��o
          ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-24),'YYYYMM'));
          ln_end_yyyymm   := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-12),'YYYYMM'));
          -- ==================================================
          -- ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(�O�X�N�x)(A-8)
          -- ==================================================
          year_data_select(
                            lv_location_cd                --���_�R�[�h
                           ,lv_item_no                    --�i�ڃR�[�h
                           ,ln_start_yyyymm               --�J�n�N��
                           ,ln_end_yyyymm                 --�I���N��
                           ,ln_befor_last_year_amount     --�O�X�N�x�N�Ԑ��ʌv
                           ,ln_befor_last_year_budget     --�O�X�N�x�N�Ԕ���v
                           ,lv_errbuf                     --�G���[�E���b�Z�[�W
                           ,lv_retcode                    --���^�[���E�R�[�h
                           ,lv_errmsg                     --���[�U�[�E�G���[�E���b�Z�[�W
                          );
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          IF (ln_befor_last_year_amount IS NULL) OR (ln_befor_last_year_amount = 0) THEN
            -- ==================================================
            -- ���f�[�^�쐬(����2�����̏ꍇ)(A-8)
            -- ==================================================
            temp_2months_data(
                              lv_location_cd,                  --���_�R�[�h
                              lv_item_no,                      --�i�ڃR�[�h
                              ln_discrete_cost,                --�c�ƌ���
                              ln_amount,                       --����
                              ln_sales_budget,                 --����
                              ln_margin,                       --�e���v
                              lv_errbuf,                       --�G���[�E���b�Z�[�W
                              lv_retcode,                      --���^�[���E�R�[�h
                              lv_errmsg);                      --���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
          ELSE
            --�O�N�x�̎��ђ��o
            ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-12),'YYYYMM'));
            ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
            -- ==================================================
            -- ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(�O�N�x)(A-8)
            -- ==================================================
            year_data_select(
                            lv_location_cd                --���_�R�[�h
                           ,lv_item_no                    --�i�ڃR�[�h
                           ,ln_start_yyyymm               --�J�n�N��
                           ,ln_end_yyyymm                 --�I���N��
                           ,ln_last_year_amount           --�O�N�x�N�Ԑ��ʌv
                           ,ln_last_year_budget           --�O�N�x�N�Ԕ���v
                           ,lv_errbuf                     --�G���[�E���b�Z�[�W
                           ,lv_retcode                    --���^�[���E�R�[�h
                           ,lv_errmsg                     --���[�U�[�E�G���[�E���b�Z�[�W
                          );
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_last_year_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            --���є䗦�̎Z�o(�O�N�x���с��O�X�N�x����)
            ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
            ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
            -- ==================================================
            -- ���f�[�^�쐬(�Ώی��̃f�[�^���o)(A-8)
            -- ==================================================
            obj_month_data_select(
                                  lv_location_cd               --���_�R�[�h
                                 ,lv_item_no                   --�i�ڃR�[�h
                                 ,ln_obj_year                  --�Ώ۔N
                                 ,ln_month_no                  --�Ώی�
                                 ,ln_obj_amount                --�Ώ۔N������
                                 ,ln_obj_sales_budget          --�Ώ۔N������
                                 ,lv_errbuf                    --�G���[�E���b�Z�[�W
                                 ,lv_retcode                   --���^�[���E�R�[�h
                                 ,lv_errmsg);                  --���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_obj_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            --���f�[�^�̔�����Z�o
            ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
            --���f�[�^�̐��ʂ��Z�o
            ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
            --���f�[�^�̑e���v���Z�o
            ln_margin :=ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
          END IF;
        --2�D�V���i2���N�x����(�^�p�N����12�����O�܂łɁA�����N������3�����ԓ��̃f�[�^�����݂���ꍇ)�̉��f�[�^�쐬
        ELSIF ln_start_months < 27 AND ln_process_months > 15 THEN
          --�O�X�N�x�̎��ђ��o
          ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_sales_start,3),'YYYYMM'));
          ln_end_yyyymm   := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-12),'YYYYMM'));
          -- ==================================================
          -- ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(�O�X�N�x)(A-8)
          -- ==================================================
          year_data_select(
                            lv_location_cd                --���_�R�[�h
                           ,lv_item_no                    --�i�ڃR�[�h
                           ,ln_start_yyyymm               --�J�n�N��
                           ,ln_end_yyyymm                 --�I���N��
                           ,ln_befor_last_year_amount     --�O�X�N�x�N�Ԑ��ʌv
                           ,ln_befor_last_year_budget     --�O�X�N�x�N�Ԕ���v
                           ,lv_errbuf                     --�G���[�E���b�Z�[�W
                           ,lv_retcode                    --���^�[���E�R�[�h
                           ,lv_errmsg                     --���[�U�[�E�G���[�E���b�Z�[�W
                          );
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          IF (ln_befor_last_year_amount IS NULL) OR (ln_befor_last_year_amount = 0) THEN
            -- ==================================================
            -- ���f�[�^�쐬(����2�����̏ꍇ)(A-8)
            -- ==================================================
            temp_2months_data(
                              lv_location_cd,                  --���_�R�[�h
                              lv_item_no,                      --�i�ڃR�[�h
                              ln_discrete_cost,                --�c�ƌ���
                              ln_amount,                       --����
                              ln_sales_budget,                 --����
                              ln_margin,                       --�e���v
                              lv_errbuf,                       --�G���[�E���b�Z�[�W
                              lv_retcode,                      --���^�[���E�R�[�h
                              lv_errmsg);                      --���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
          ELSE
            --�O�N�x�̎��ђ��o
            ln_start_yyyymm := TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_sales_start,15),'YYYYMM'));
            ln_end_yyyymm   := TO_NUMBER(TO_CHAR(cd_process_date,'YYYYMM'));
            -- ==================================================
            -- ���f�[�^�쐬(�Ώ۔N�x�̔N�Ԏ��ђ��o)(�O�N�x)(A-8)
            -- ==================================================
            year_data_select(
                            lv_location_cd                --���_�R�[�h
                           ,lv_item_no                    --�i�ڃR�[�h
                           ,ln_start_yyyymm               --�J�n�N��
                           ,ln_end_yyyymm                 --�I���N��
                           ,ln_last_year_amount           --�O�N�x�N�Ԑ��ʌv
                           ,ln_last_year_budget           --�O�N�x�N�Ԕ���v
                           ,lv_errbuf                     --�G���[�E���b�Z�[�W
                           ,lv_retcode                    --���^�[���E�R�[�h
                           ,lv_errmsg                     --���[�U�[�E�G���[�E���b�Z�[�W
                          );
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_last_year_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            
            --���є䗦�̎Z�o(�O�N�x���с��O�X�N�x����)
            ln_result_budget_rate := ln_last_year_budget/ln_befor_last_year_budget;
            ln_result_amount_rate := ln_last_year_amount/ln_befor_last_year_amount;
            -- ==================================================
            -- ���f�[�^�쐬(�Ώی��̃f�[�^���o)(A-8)
            -- ==================================================
            obj_month_data_select(
                                  lv_location_cd               --���_�R�[�h
                                 ,lv_item_no                   --�i�ڃR�[�h
                                 ,ln_obj_year                  --�Ώ۔N�x
                                 ,ln_month_no                  --�Ώی�
                                 ,ln_obj_amount                --�Ώ۔N������
                                 ,ln_obj_sales_budget          --�Ώ۔N������
                                 ,lv_errbuf                    --�G���[�E���b�Z�[�W
                                 ,lv_retcode                   --���^�[���E�R�[�h
                                 ,lv_errmsg);                  --���[�U�[�E�G���[�E���b�Z�[�W
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            IF ln_obj_sales_budget IS NULL THEN
              RAISE no_data_skip_expt;
            END IF;
            --���f�[�^�̔�����Z�o
            ln_sales_budget := ROUND((ln_obj_sales_budget * ln_result_budget_rate),0);
            --���f�[�^�̐��ʂ��Z�o
            ln_amount := ROUND((ln_obj_amount * ln_result_amount_rate),0);
            --���f�[�^�̑e���v���Z�o
            ln_margin :=ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
          END IF;
        --3�D�V���i�P�N�x(�����N������^�p�N���܂�15�����ȍ~2�������ȏ�̃f�[�^�����݂���ꍇ)�̉��f�[�^�쐬
        ELSIF ln_start_months < 27 AND (ln_process_months <= 15 AND ln_process_months > 1) THEN
          -- ==================================================
          -- ���f�[�^�쐬(����2�����̏ꍇ)(A-8)
          -- ==================================================
          temp_2months_data(
                              lv_location_cd,                  --���_�R�[�h
                              lv_item_no,                      --�i�ڃR�[�h
                              ln_discrete_cost,                --�c�ƌ���
                              ln_amount,                       --����
                              ln_sales_budget,                 --����
                              ln_margin,                       --�e���v
                              lv_errbuf,                       --�G���[�E���b�Z�[�W
                              lv_retcode,                      --���^�[���E�R�[�h
                              lv_errmsg);                      --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          IF ln_sales_budget IS NULL THEN
            RAISE no_data_skip_expt;
          END IF;
        --4�D�V���i�P�N�x(�����N������^�p�N���܂ŁA�ꃖ�����̃f�[�^�̂ݑ��݂���ꍇ)�̉��f�[�^�쐬
        ELSIF ln_process_months = 1 THEN
          --�Ώی��Z�o
          ln_obj_year  := ln_subject_year;
          ln_obj_month := TO_NUMBER(TO_CHAR(ADD_MONTHS(cd_process_date,-1),'MM'));
          -- ==================================================
          -- ���f�[�^�쐬(�Ώی��̃f�[�^���o)(A-8)
          -- ==================================================
          obj_month_data_select(
                                lv_location_cd               --���_�R�[�h
                               ,lv_item_no                   --�i�ڃR�[�h
                               ,ln_obj_year                  --�Ώ۔N�x
                               ,ln_obj_month                 --�Ώی�
                               ,ln_obj_amount                --�Ώ۔N������
                               ,ln_obj_sales_budget          --�Ώ۔N������
                               ,lv_errbuf                    --�G���[�E���b�Z�[�W
                               ,lv_retcode                   --���^�[���E�R�[�h
                               ,lv_errmsg);                  --���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          IF ln_obj_sales_budget IS NULL THEN
            RAISE no_data_skip_expt;
          END IF;
          --���f�[�^�̔�����Z�o
          ln_sales_budget := ln_obj_sales_budget;
          --���f�[�^�̐��ʂ��Z�o
          ln_amount := ln_obj_amount;
          --���f�[�^�̑e���v���Z�o
          ln_margin := ROUND((ln_sales_budget - (ln_amount * ln_discrete_cost)),0);
        END IF;
--
        --���f�[�^���݂���ꍇ�����A�f�[�^��o�^
        IF ln_sales_budget IS NOT NULL THEN
          -- ===================================
          -- ���i�v��p�̔����уe�[�u���o�^����(A-9)
          -- ===================================
          insert_plan_result(
                             ln_subject_year                -- �Ώ۔N�x
                            ,ln_year_month                  -- �N��
                            ,ln_month_no                    -- ��
                            ,lv_location_cd                 -- ���_�R�[�h
                            ,lv_item_no                     -- ���i�R�[�h
                            ,lv_group_cd                    -- ���i�Q�R�[�h
                            ,ln_amount                      -- ����
                            ,ln_sales_budget                -- ������z
                            ,ln_margin                      -- �e���v
                            ,lv_errbuf                      -- �G���[�E���b�Z�[�W
                            ,lv_retcode                     -- ���^�[���E�R�[�h
                            ,lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          gn_temp_normal_cnt := gn_temp_normal_cnt + 1;
        END IF;
      EXCEPTION
        WHEN temp_skip_expt THEN
          gn_temp_error_cnt := gn_temp_error_cnt + 1;
          fnd_file.put_line(
                             which  => FND_FILE.LOG
                            ,buff   => lv_errbuf
                            );
          fnd_file.put_line(
                          which  => FND_FILE.OUTPUT
                         ,buff   => lv_errmsg
                         );
        WHEN no_data_skip_expt THEN
          --�������Ȃ�
          NULL;
      END;
    END LOOP;
--
  EXCEPTION
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END temp_data_make;
  
  /**********************************************************************************
   * Procedure Name   : sales_result_select
   * Description      : �̔����ђ��o����(A-2)
   ***********************************************************************************/
  PROCEDURE sales_result_select(
    ov_errbuf        OUT NOCOPY VARCHAR2,                           -- �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,                           -- ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'sales_result_select';            -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg         VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    cv_sales_class   CONSTANT VARCHAR2(100) := 'XXCSM1_EXCLUSION_SALES_CLASS';     --�̔����яW�v���O����敪
--//+DEL END 2009/08/03 0000479 T.Tsukino
--//ADD START 2009/05/01 T1_0861 M.Ohtsuki
    cv_sp_item_cd        CONSTANT VARCHAR2(100) := 'XXCSM1_SPECIAL_ITEM';          --����i�ڃR�[�h
--//ADD END   2009/05/01 T1_0861 M.Ohtsuki
--//ADD START 2009/06/03 T1_1174 M.Ohtsuki
    cv_flg_on            CONSTANT VARCHAR2(1) := '1';                              --�t���OON
    cv_flg_off           CONSTANT VARCHAR2(1) := '0';                              --�t���OOFF
    
--//ADD END   2009/06/03 T1_1174 M.Ohtsuki
    -- *** ���[�J���ϐ� ***
--
    ln_result_cnt                 NUMBER;                      --�̔����ђ��o����
    ln_subject_year               NUMBER;                      --�Ώ۔N�x
    ln_year_month                 NUMBER;                      --�N��
    ln_month_no                   NUMBER;                      --��
    lv_location_cd                VARCHAR2(9);                 --���_�R�[�h
    lv_item_no                    VARCHAR2(32);                --�i�ڃR�[�h
    ln_amount                     NUMBER;                      --���ʌ��v
    ln_sales_budget               NUMBER;                      --���㌎�v
    ln_margin_you                 NUMBER;                      --�e���v�Z�o�p�f�[�^
    ln_margin                     NUMBER;                      --�e���v���v
    lv_group_cd                   VARCHAR2(100);                 --���i�Q�R�[�h
    lv_opm_item_no                VARCHAR2(32);                --OPM�i�ڃ}�X�^�i�ڃR�[�h
    lv_start_date                 VARCHAR2(100);                 --������
    lv_location_pre               VARCHAR2(9);                 --�ۑ��p���_�R�[�h
    lv_item_no_pre                VARCHAR2(32);                --�ۑ��p�i�ڃR�[�h
    lv_group_cd_pre               VARCHAR2(100);                 --�ۑ��p���i�Q�R�[�h
    lv_start_date_pre             VARCHAR2(100);                 --�ۑ��p������
    ln_discrete_cost_pre          NUMBER;                      --�ۑ��p�c�ƌ���
    ln_discrete_cost              NUMBER;                      --�c�ƌ���
    lb_create_data                BOOLEAN;                     --���f�[�^�쐬�t���O
    lb_skip_flg                   BOOLEAN;                     --�i�ڒP�ʂŃX�L�b�v�t���O
    lb_group_skip_flg             BOOLEAN;                     --���i�Q�擾�ł��Ȃ��X�L�b�v�t���O
    opm_item_count                number;
    -- *** ���[�J���E�J�[�\�� ***
      /**      �̔����уf�[�^���o       **/
    CURSOR sales_result_cur
    IS
--//+UPD START   2009/03/18  �d�l�ύX  S.Son
--      SELECT  xsh.year_month                               year_month                 --�[�i�N��
--             ,xsh.month                                    month                      --�[�i��
--             ,xsh.sale_base_code                           sale_base_code             --���㋒�_�R�[�h
--             ,xselv.item_code                               item_code                 --�i�ڃR�[�h
--             ,SUM(xselv.standard_qty)                       month_sumary_qty          --�����
--             ,SUM(xselv.pure_amount)                        month_sumary_pure_amount  --�{�̋��z
--             ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))  month_sumary_margin       --�e���v�Z�o�p
--      FROM   (SELECT xsehv.sales_exp_header_id              sales_exp_header_id       --�̔����уw�b�_ID
--                    ,TO_CHAR(xsehv.delivery_date,'YYYYMM')  year_month                --�[�i�N��
--                    ,TO_CHAR(xsehv.delivery_date,'MM')      month                     --�[�i��
--                    ,DECODE(xca.rsv_sale_base_act_date                                --�\�񔄏㋒�_�L���J�n��
--                           ,gt_start_date                                             --�\�Z�N�x�J�n��
--                           ,xca.rsv_sale_base_code                                    --�\�񔄏㋒�_�R�[�h
--                           ,xca.sale_base_code                                        --���㋒�_�R�[�h
--                           )  sale_base_code                 --�N���ؑ֋��_�̏ꍇ�A�Ώ۔N�x�ɓK�p����鋒�_�𓱏o
--              FROM   xxcsm_sales_exp_headers_v   xsehv                                --�̔����уw�b�_�e�[�u���r���[
--                     ,xxcmm_cust_accounts      xca                                    --�ڋq�ǉ����
--              WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')      --�\�Z�쐬�N�x�J�n���|24����
--              AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')
--              AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')    --�R���J�����g�N���N���O�̃f�[�^��ΏۂƂ���
--              AND    xsehv.ship_to_customer_code = xca.customer_code                  --�ڋq�y�[�i��z=�ڋq�R�[�h(�ڋq�ǉ����)
--             ) xsh                                                                    --�̔����уC�����C���r���[
--             ,xxcsm_sales_exp_lines_v    xselv                                        --�̔����і��׃e�[�u���r���[
--             ,xxcsm_tmp_cust_accounts         xtca                                     --�ڋq��񃏁[�N�e�[�u���i���_�̃f�[�^�̂݁j
--//+ADD START 2009/03/04 CT075 S.Son
--             ,xxcsm_commodity_group4_v   xcg4v                                         --���i�Q�S�r���[
--//+ADD END 2009/03/04 CT075 S.Son
--      WHERE  xsh.sales_exp_header_id = xselv.sales_exp_header_id                      --�̔����уw�b�_ID�̕R�t��
--      AND    xsh.sale_base_code = xtca.account_number                                 --���㋒�_�R�[�h=�ڋq�R�[�h
--//+UPD START 2009/02/26 CT057 S.Son
--    --AND    MOD(xtca.cust_account_id,TO_NUMBER(gv_parallel_cnt)) 
--      AND    xtca.cust_account_id 
--                  = TO_NUMBER(gv_parallel_value_no)                                   --���_��ID�ɂăp������
--//+UPD START 2009/02/26 CT057 S.Son
--      AND    xsh.sale_base_code = NVL(gv_location_cd,xsh.sale_base_code)              --���̓p�����[�^���_�R�[�hNULL�̏ꍇ
--                                                                                      --�p���������A���_�R�[�h���擾
--      AND    xselv.item_code     = NVL(gv_item_no,xselv.item_code)                    --���̓p�����[�^�i�ڃR�[�hNULL�̏ꍇ
--                                                                                      --�Ώەi�ڃR�[�h���ׂĂ��擾
--//+ADD START 2009/03/04 CT075 S.Son
--      AND    xcg4v.item_cd  =  xselv.item_code                                        --���i�Q�S�r���[��R�t��
--      AND    xcg4v.group4_cd <> gv_discount_cd                                        --�l���p�i��(DAAE)�ȊO
--//+ADD END 2009/03/04 CT075 S.Son
--      AND    NOT EXISTS (SELECT 'X'
--                         FROM   fnd_lookup_values flv                                            --�N�C�b�N�R�[�h�l
--                         WHERE  flv.lookup_type = cv_sales_class                                 --�̔����яW�v���O����敪
--                         AND    flv.enabled_flag = cv_flg_y                                      --�L���t���O
--                         AND    flv.language = cv_language_ja                                    --����
--                         AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date   --�J�n��
--                         AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date   --�I����
--                         AND    flv.lookup_code = xselv.sales_class)                             --���b�N�A�b�v�R�[�h=����敪
--      GROUP BY  xsh.sale_base_code                 --���㋒�_�R�[�h
--               ,xselv.item_code                    --�i�ڃR�[�h
--               ,xsh.year_month                     --�[�i�N��
--               ,xsh.month                          --�[�i��
--      ORDER BY  xsh.sale_base_code                 --���㋒�_�R�[�h
--              ,xselv.item_code                    --�i�ڃR�[�h
--               ,xsh.year_month                     --�[�i�N��
--    ;
--��������������������������������������������������������������������������������������������������
--//+UPD START 2009/06/03 T1_1174 M.Ohtsuki
--   SELECT  xse.year_month                                        year_month                         -- �N��
--          ,xse.month                                             month                              -- ��
--          ,xse.sale_base_code                                    sale_base_code                     -- ���㋒�_�R�[�h
--          ,xse.item_code                                         item_code                          -- �i�ڃR�[�h
--          ,SUM(xse.month_sumary_qty)                             month_sumary_qty                   -- ������z
--          ,SUM(xse.month_sumary_pure_amount)                     month_sumary_pure_amount           -- ����
--          ,SUM(xse.month_sumary_margin)                          month_sumary_margin                -- �e���v�Z�o�p
--   FROM   (SELECT  TO_CHAR(xsti.selling_date,'YYYYMM')           year_month                         -- ����v���(�N��)
--                  ,TO_CHAR(xsti.selling_date,'MM')               month                              -- ����v���(��)
--                  ,xcai.sale_base_code                            sale_base_code                    -- ���㋒�_�R�[�h
--                  ,xsti.item_code                                item_code                          -- �i�ڃR�[�h
--                  ,SUM(xsti.qty)                                 month_sumary_qty                   -- �����
--                  ,SUM(xsti.selling_amt)                         month_sumary_pure_amount           -- �{�̋��z
--                  ,SUM(xsti.qty * NVL(xsti.trading_cost,0))      month_sumary_margin                -- �e���v�Z�o�p
--          FROM    (SELECT  DISTINCT xsti.slip_no                 slip_no                            -- �`�[�ԍ�
--                   FROM    xxcok_selling_trns_info               xsti                               -- ���ѐU�փe�[�u��
--                          ,xxcmm_cust_accounts                   xca                                -- �ǉ��ڋq���e�[�u��
--                          ,xxcsm_sales_exp_headers_v             xsehv                              -- �̔����уw�b�_�r���[
--                   WHERE  xsehv.ship_to_customer_code = xca.customer_code                           -- �ڋq�R�[�h�ŕR�t��
--                   AND    xsehv.ship_to_customer_code = xsti.cust_code                              -- �ڋq�R�[�h�ŕR�t��
--                   )                                             sti
--                  ,(SELECT      DISTINCT xsti.cust_code          cust_code
--                               ,DECODE(xca.rsv_sale_base_act_date                                   -- �\�񔄏㋒�_�L���J�n��
--                                       ,gt_start_date                                               -- �\�Z�N�x�J�n��
--                                       ,xca.rsv_sale_base_code                                      -- �\�񔄏㋒�_�R�[�h
--                                       ,xca.sale_base_code                                          -- ���㋒�_�R�[�h
--                                       )                         sale_base_code
--                   FROM    xxcok_selling_trns_info               xsti                               -- ���ѐU�փe�[�u��
--                          ,xxcmm_cust_accounts                   xca                                -- �ǉ��ڋq���e�[�u��
--                   WHERE  xsti.cust_code = xca.customer_code                                        -- �ڋq�R�[�h�ŕR�t��
--                   )   xcai
--                  ,xxcok_selling_trns_info                       xsti                               -- ���ѐU�փe�[�u��
--                  ,xxcsm_tmp_cust_accounts                       xtca                               -- �ڋq��񃏁[�N�e�[�u���i���_�̃f�[�^�̂݁j
--                  ,xxcsm_commodity_group4_v                      xcg4v                              -- ���i�Q�S�r���[
--          WHERE   xcai.sale_base_code  = xtca.account_number                                        -- ���㋒�_�R�[�h = �ڋq�R�[�h
--          AND     xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)                            -- ���_��ID�ɂăp������
--          AND     xcai.sale_base_code  = NVL(gv_location_cd,xcai.sale_base_code)                    -- ���̓p�����[�^���_�R�[�hNULL�̏ꍇ
--          AND     xsti.item_code       = NVL(gv_item_no,xsti.item_code)                             -- ���̓p�����[�^�i�ڃR�[�hNULL�̏ꍇ
--          AND     sti.slip_no          = xsti.slip_no                                               -- �`�[�ԍ��R�t��
--          AND     xcai.cust_code       = xsti.cust_code                                             -- �ڋq�R�[�h�R�t��
--          AND     TRUNC(xsti.selling_date,'MM')   >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')      -- �\�Z�쐬�N�x�J�n���|24����
--          AND     TRUNC(xsti.selling_date,'MM')   <  TRUNC(gt_start_date,'MM')                      -- �N�x�J�n�����O�̃f�[�^
--          AND     TRUNC(xsti.selling_date,'MM')   <  TRUNC(cd_process_date,'MM')                    -- �R���J�����g�N���N���O�̃f�[�^��ΏۂƂ���
--          AND     (xsti.report_decision_flag = 1                                                    -- ����m��t���O = �m��
--                  OR 
--                  (TRUNC(xsti.selling_date,'MM')   = TRUNC(ADD_MONTHS(cd_process_date,-1),'MM')     -- �Ɩ����t�O��
--                     AND xsti.report_decision_flag = 0                                              -- ����m��t���O = ����
--                     AND xsti.correction_flag      = 0)                                             -- �U�߃t���O = 0 (�ŐV�̃f�[�^)
--                   )
--          AND      xsti.item_code   = xcg4v.item_cd                                                 -- �i�ڃR�[�h�R�t��
--          AND      xcg4v.group4_cd <> gv_discount_cd                                                -- �l���p�i��(DAAE)�ȊO
--//+ADD START 2009/05/01 T1_0861 M.Ohtsuki
--          AND    NOT EXISTS (SELECT 'X'
--                             FROM   fnd_lookup_values flv                                           --�N�C�b�N�R�[�h�l
--                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --�����ΏۊO����i��
--                             AND    flv.enabled_flag = cv_flg_y                                     --�L���t���O
--                             AND    flv.language = cv_language_ja                                   --����
--                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --�J�n��
--                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --�I����
--                             AND    flv.lookup_code = xsti.item_code)                               --���b�N�A�b�v�R�[�h=�i�ڃR�[�h
--//+ADD END   2009/05/01 T1_0861 M.Ohtsuki
--          GROUP BY xcai.sale_base_code                                                              -- ���㋒�_�R�[�h
--                  ,xsti.item_code                                                                   -- �i�ڃR�[�h
--                  ,TO_CHAR(xsti.selling_date,'YYYYMM')                                              -- �[�i�N��
--                  ,TO_CHAR(xsti.selling_date,'MM')                                                  -- �[�i��
--        UNION ALL
--          SELECT  xsh.year_month                                 year_month                         -- �N��
--                 ,xsh.month                                      month                              -- ��
--                 ,xsh.sale_base_code                             sale_base_code                     -- ���㋒�_�R�[�h
--                 ,xselv.item_code                                item_code                          -- �i�ڃR�[�h
--                 ,SUM(xselv.standard_qty)                        month_sumary_qty                   -- �����
--                 ,SUM(xselv.pure_amount)                         month_sumary_pure_amount           -- �{�̋��z
--                 ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))
--                                                                 month_sumary_margin                -- �e���v�Z�o�p
--          FROM   (SELECT xsehv.sales_exp_header_id               sales_exp_header_id                -- �̔����уw�b�_ID
--                        ,xsehv.ship_to_customer_code             ship_to_customer_code              -- �ڋq�R�[�h
--                        ,TO_CHAR(xsehv.delivery_date,'YYYYMM')   year_month                         -- �[�i��(�N��)
--                        ,TO_CHAR(xsehv.delivery_date,'MM')       month                              -- �[�i��(��)
--                        ,DECODE(xca.rsv_sale_base_act_date                                          -- �\�񔄏㋒�_�L���J�n��
--                               ,gt_start_date                                                       -- �\�Z�N�x�J�n��
--                               ,xca.rsv_sale_base_code                                              -- �\�񔄏㋒�_�R�[�h
--                               ,xca.sale_base_code                                                  -- ���㋒�_�R�[�h
--                               )                                 sale_base_code                     -- �N���ؑ֋��_�̏ꍇ�A�Ώ۔N�x�ɓK�p����鋒�_�𓱏o
--                  FROM   xxcsm_sales_exp_headers_v               xsehv                              -- �̔����уw�b�_�e�[�u���r���[
--                        ,xxcmm_cust_accounts      xca                                               -- �ڋq�ǉ����
--                  WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')-- �\�Z�쐬�N�x�J�n���|24����
--                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')                -- �N�x�J�n���O�̃f�[�^���Ώ�
--                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')              -- �R���J�����g�N���N���O�̃f�[�^��ΏۂƂ���
--                  AND    xsehv.ship_to_customer_code = xca.customer_code                            -- �ڋq�y�[�i��z=�ڋq�R�[�h(�ڋq�ǉ����)
--                 )                                               xsh                                -- �̔����уC�����C���r���[
--                 ,xxcsm_sales_exp_lines_v                        xselv                              -- �̔����і��׃e�[�u���r���[
--                 ,xxcsm_tmp_cust_accounts                        xtca                               -- �ڋq��񃏁[�N�e�[�u���i���_�̃f�[�^�̂݁j
--                 ,xxcsm_commodity_group4_v                       xcg4v                              -- ���i�Q�S�r���[
--          WHERE   xsh.sales_exp_header_id = xselv.sales_exp_header_id                               -- �̔����уw�b�_ID�̕R�t��
--          AND     xsh.sale_base_code      = xtca.account_number                                     -- ���㋒�_�R�[�h=�ڋq�R�[�h
--          AND     xtca.cust_account_id    = TO_NUMBER(gv_parallel_value_no)                         -- ���_��ID�ɂăp������
--          AND     xsh.sale_base_code      = NVL(gv_location_cd,xsh.sale_base_code)                  -- ���̓p�����[�^���_�R�[�hNULL�̏ꍇ�S��
--          AND     xselv.item_code         = NVL(gv_item_no,xselv.item_code)                         -- ���̓p�����[�^�i�ڃR�[�hNULL�̏ꍇ�S��
--          AND     xcg4v.item_cd           =  xselv.item_code                                        -- ���i�Q�S�r���[��R�t��
--          AND     xcg4v.group4_cd        <> gv_discount_cd                                          -- �l���p�i��(DAAE)�ȊO
--          AND     NOT EXISTS (SELECT xsti.base_code                                                 -- ���ѐU�փe�[�u���ɑ��݂��Ȃ�
--                              FROM   xxcok_selling_trns_info     xsti                               -- ���ѐU�փe�[�u��
--                              WHERE  TO_CHAR(xsti.selling_date,'YYYYMM') = xsh.year_month           -- ����v��� = �[�i��
--                              AND    xsti.cust_code     = xsh.ship_to_customer_code                 -- �ڋq�R�[�h
--                              AND    xsti.item_code     = xselv.item_code                           -- �i�ڃR�[�h
--                              )
--//+ADD START 2009/05/01 T1_0861 M.Ohtsuki
--          AND    NOT EXISTS (SELECT 'X'
--                             FROM   fnd_lookup_values flv                                           --�N�C�b�N�R�[�h�l
--                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --�����ΏۊO����i��
--                             AND    flv.enabled_flag = cv_flg_y                                     --�L���t���O
--                             AND    flv.language = cv_language_ja                                   --����
--                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --�J�n��
--                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --�I����
--                             AND    flv.lookup_code = xselv.item_code)                              --���b�N�A�b�v�R�[�h=�i�ڃR�[�h
--//+ADD END   2009/05/01 T1_0861 M.Ohtsuki
--          GROUP BY  xsh.sale_base_code                                                              -- ���㋒�_�R�[�h
--                   ,xselv.item_code                                                                 -- �i�ڃR�[�h
--                   ,xsh.year_month                                                                  -- �[�i�N��
--                   ,xsh.month                                                                       -- �[�i��
--          ) xse
--   GROUP BY  xse.year_month                                                                         -- �N��
--            ,xse.sale_base_code                                                                     -- ���㋒�_�R�[�h
--            ,xse.item_code                                                                          -- �i�ڃR�[�h
--            ,xse.month                                                                              -- ��
--   ORDER BY  xse.sale_base_code                                                                     -- ���㋒�_�R�[�h
--            ,xse.item_code                                                                          -- �i�ڃR�[�h
--            ,xse.year_month;                                                                        -- �N��
--//+UPD END   2009/03/18  �d�l�ύX  S.Son
--��������������������������������������������������������������������������������������������������
--//+UPD START 2009/08/03 0000479 T.Tsukino
--//+DEL START 2009/08/03 0000479 T.Tsukino
--��������������������������������������������������������������������������������������������������������������������������������
--   SELECT  xse.year_month                                        year_month                         -- �N��
--          ,xse.month                                             month                              -- ��
--          ,xse.sale_base_code                                    sale_base_code                     -- ���㋒�_�R�[�h
--          ,xse.item_code                                         item_code                          -- �i�ڃR�[�h
--          ,SUM(xse.month_sumary_qty)                             month_sumary_qty                   -- ������z
--          ,SUM(xse.month_sumary_pure_amount)                     month_sumary_pure_amount           -- ����
--          ,SUM(xse.month_sumary_margin)                          month_sumary_margin                -- �e���v�Z�o�p
--   FROM   (
--          --���ѐU��
--          SELECT  xcai.selling_date                              year_month                         -- ����v���(�N��)
--                 ,substrb(xcai.selling_date,5,2)                 month                              -- ����v���(��)
--                 ,xcai.sale_base_code                            sale_base_code                     -- ���㋒�_�R�[�h
--                 ,xcai.item_code                                 item_code                          -- �i�ڃR�[�h
--                 ,SUM(xcai.qty)                                  month_sumary_qty                   -- �����
--                 ,SUM(xcai.selling_amt)                          month_sumary_pure_amount           -- �{�̋��z
--                 ,SUM(xcai.qty * NVL(xcai.trading_cost,0))       month_sumary_margin                -- �e���v�Z�o�p
--          FROM   (SELECT DISTINCT xsti.cust_code                 cust_code                          -- �ڋq�R�[�h
--                        ,xsti.item_code                          item_code                          -- �i�ڃR�[�h
--                        ,TO_CHAR(xsti.selling_date,'YYYYMM')     selling_date                       -- ����v���
--                        ,DECODE(xca.rsv_sale_base_act_date                                          -- �\�񔄏㋒�_�L���J�n��
--                               ,gt_start_date                                                       -- �\�Z�N�x�J�n��
--                               ,xca.rsv_sale_base_code                                              -- �\�񔄏㋒�_�R�[�h
--                              ,xca.sale_base_code                                                  -- ���㋒�_�R�[�h
--                               )                                 sale_base_code
--                        ,xsti.qty                                qty                                -- ����
--                        ,xsti.selling_amt                        selling_amt                        -- �{�̋��z
--                        ,xsti.trading_cost                       trading_cost                       -- �c�ƌ���
--                  FROM   xxcok_selling_trns_info                 xsti                               -- ���ѐU�փe�[�u��
--                        ,xxcmm_cust_accounts                     xca                                -- �ǉ��ڋq���e�[�u��
--                  WHERE  xsti.cust_code = xca.customer_code                                         -- �ڋq�R�[�h�ŕR�t��
--                  AND    xsti.item_code = NVL(gv_item_no,xsti.item_code)                            -- ���̓p�����[�^�i�ڃR�[�hNULL�̏ꍇ
--                  AND   (xsti.report_decision_flag = cv_flg_on                                         -- ����m��t���O = �m��
--                    OR  (TRUNC(xsti.selling_date,'MM')   = TRUNC(ADD_MONTHS(cd_process_date,-1),'MM')  -- �Ɩ����t�O��
--                           AND xsti.report_decision_flag = cv_flg_off                                           -- ����m��t���O = ����
--                           AND xsti.correction_flag      = cv_flg_off)                                          -- �U�߃t���O = 0 (�ŐV�̃f�[�^)
--                        )
--                  AND    TRUNC(xsti.selling_date,'MM')   >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')  -- �\�Z�쐬�N�x�J�n���|24����
--                  AND    TRUNC(xsti.selling_date,'MM')   <  TRUNC(gt_start_date,'MM')                  -- �N�x�J�n�����O�̃f�[�^
--                  AND    TRUNC(xsti.selling_date,'MM')   <  TRUNC(cd_process_date,'MM')                -- �R���J�����g�N���N���O�̃f�[�^��ΏۂƂ���
--                  )   xcai                                                                          -- ���ѐU�փC�����C���r���[
--                 ,xxcsm_tmp_cust_accounts                       xtca                                -- �ڋq��񃏁[�N�e�[�u���i���_�̃f�[�^�̂݁j
--                 ,xxcsm_commodity_group4_v                      xcg4v                               -- ���i�Q�S�r���[
--          WHERE   xcai.sale_base_code  = xtca.account_number                                        -- ���㋒�_�R�[�h = �ڋq�R�[�h
--          AND     xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)                            -- ���_��ID�ɂăp������
--          AND     xcai.sale_base_code  = NVL(gv_location_cd,xcai.sale_base_code)                    -- ���̓p�����[�^���_�R�[�hNULL�̏ꍇ
--          AND     xcai.item_code       = xcg4v.item_cd                                              -- �i�ڃR�[�h�R�t��
--          AND     xcg4v.group4_cd     <> gv_discount_cd                                             -- �l���p�i��(DAAE)�ȊO
--          AND     NOT EXISTS (SELECT 'X'
--                             FROM   fnd_lookup_values flv                                           -- �N�C�b�N�R�[�h�l
--                             WHERE  flv.lookup_type = cv_sp_item_cd                                 -- �����ΏۊO����i��
--                             AND    flv.enabled_flag = cv_flg_y                                     -- �L���t���O
--                             AND    flv.language = cv_language_ja                                   -- ����
--                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  -- �J�n��
--                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  -- �I����
--                             AND    flv.lookup_code = xcai.item_code)                               -- ���b�N�A�b�v�R�[�h=�i�ڃR�[�h
--          GROUP BY xcai.sale_base_code                                                              -- ���㋒�_�R�[�h
--                  ,xcai.item_code                                                                   -- �i�ڃR�[�h
--                 ,xcai.selling_date                                                                -- �[�i�N��
--                  ,substrb(xcai.selling_date,5,2)                                                   -- �[�i��
--        UNION ALL
--          --�̔�����
--          SELECT  xsh.year_month                                 year_month                         -- �N��
--                 ,xsh.month                                      month                              -- ��
--                 ,xsh.sale_base_code                             sale_base_code                     -- ���㋒�_�R�[�h
--                 ,xselv.item_code                                item_code                          -- �i�ڃR�[�h
--                 ,SUM(xselv.standard_qty)                        month_sumary_qty                   -- �����
--                 ,SUM(xselv.pure_amount)                         month_sumary_pure_amount           -- �{�̋��z
--                 ,SUM(xselv.standard_qty * NVL(xselv.business_cost,0))
--                                                                 month_sumary_margin                -- �e���v�Z�o�p
--          FROM   (SELECT xsehv.sales_exp_header_id               sales_exp_header_id                -- �̔����уw�b�_ID
--                        ,xsehv.ship_to_customer_code             ship_to_customer_code              -- �ڋq�R�[�h
--                        ,TO_CHAR(xsehv.delivery_date,'YYYYMM')   year_month                         -- �[�i��(�N��)
--                        ,TO_CHAR(xsehv.delivery_date,'MM')       month                              -- �[�i��(��)
--                        ,DECODE(xca.rsv_sale_base_act_date                                          -- �\�񔄏㋒�_�L���J�n��
--                               ,gt_start_date                                                       -- �\�Z�N�x�J�n��
--                               ,xca.rsv_sale_base_code                                              -- �\�񔄏㋒�_�R�[�h
--                               ,xca.sale_base_code                                                  -- ���㋒�_�R�[�h
--                               )                                 sale_base_code                     -- �N���ؑ֋��_�̏ꍇ�A�Ώ۔N�x�ɓK�p����鋒�_�𓱏o
--                  FROM   xxcsm_sales_exp_headers_v               xsehv                              -- �̔����уw�b�_�e�[�u���r���[
--                        ,xxcmm_cust_accounts      xca                                               -- �ڋq�ǉ����
--                  WHERE  TRUNC(xsehv.delivery_date,'MM') >= TRUNC(ADD_MONTHS(gt_start_date,-24),'MM')  -- �\�Z�쐬�N�x�J�n���|24����
--                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(gt_start_date,'MM')                -- �N�x�J�n���O�̃f�[�^���Ώ�
--                  AND    TRUNC(xsehv.delivery_date,'MM') < TRUNC(cd_process_date,'MM')              -- �R���J�����g�N���N���O�̃f�[�^��ΏۂƂ���
--                  AND    xsehv.ship_to_customer_code = xca.customer_code                            -- �ڋq�y�[�i��z=�ڋq�R�[�h(�ڋq�ǉ����)
--                 )                                               xsh                                -- �̔����уC�����C���r���[
--                 ,xxcsm_sales_exp_lines_v                        xselv                              -- �̔����і��׃e�[�u���r���[
--                 ,xxcsm_tmp_cust_accounts                        xtca                               -- �ڋq��񃏁[�N�e�[�u���i���_�̃f�[�^�̂݁j
--                 ,xxcsm_commodity_group4_v                       xcg4v                              -- ���i�Q�S�r���[
--          WHERE   xsh.sales_exp_header_id = xselv.sales_exp_header_id                               -- �̔����уw�b�_ID�̕R�t��
--          AND     xsh.sale_base_code      = xtca.account_number                                     -- ���㋒�_�R�[�h=�ڋq�R�[�h
--          AND     xtca.cust_account_id    = TO_NUMBER(gv_parallel_value_no)                         -- ���_��ID�ɂăp������
--          AND     xsh.sale_base_code      = NVL(gv_location_cd,xsh.sale_base_code)                  -- ���̓p�����[�^���_�R�[�hNULL�̏ꍇ�S��
--          AND     xselv.item_code         = NVL(gv_item_no,xselv.item_code)                         -- ���̓p�����[�^�i�ڃR�[�hNULL�̏ꍇ�S��
--          AND     xcg4v.item_cd           =  xselv.item_code                                        -- ���i�Q�S�r���[��R�t��
--          AND     xcg4v.group4_cd        <> gv_discount_cd                                          -- �l���p�i��(DAAE)�ȊO
--          AND    NOT EXISTS (SELECT 'X'
--                             FROM   fnd_lookup_values flv                                           --�N�C�b�N�R�[�h�l
--                             WHERE  flv.lookup_type = cv_sp_item_cd                                 --�����ΏۊO����i��
--                             AND    flv.enabled_flag = cv_flg_y                                     --�L���t���O
--                             AND    flv.language = cv_language_ja                                   --����
--                             AND    NVL(flv.start_date_active,cd_process_date)  <= cd_process_date  --�J�n��
--                             AND    NVL(flv.end_date_active,cd_process_date)    >= cd_process_date  --�I����
--                             AND    flv.lookup_code = xselv.item_code)                              --���b�N�A�b�v�R�[�h=�i�ڃR�[�h
--          GROUP BY  xsh.sale_base_code                                                              -- ���㋒�_�R�[�h
--                   ,xselv.item_code                                                                 -- �i�ڃR�[�h
--                   ,xsh.year_month                                                                  -- �[�i�N��
--                   ,xsh.month                                                                       -- �[�i��
--          ) xse
--   GROUP BY  xse.year_month                                                                         -- �N��
--            ,xse.sale_base_code                                                                     -- ���㋒�_�R�[�h
--            ,xse.item_code                                                                          -- �i�ڃR�[�h
--            ,xse.month                                                                              -- ��
--   ORDER BY  xse.sale_base_code                                                                     -- ���㋒�_�R�[�h
--            ,xse.item_code                                                                          -- �i�ڃR�[�h
--            ,xse.year_month;                                                                        -- �N��
--//+DEL END 2009/08/03 0000479 T.Tsukino
--����������������������������������������������������������������������������������������������������������������������������������
    SELECT  inn_v.year_month         year_month
           ,inn_v.month              month
           ,inn_v.sale_base_code     sale_base_code
           ,inn_v.item_code          item_code
           ,SUM(inn_v.qty)           month_sumary_qty
           ,SUM(inn_v.pure_amount)   month_sumary_pure_amount
           ,SUM(inn_v.trading_cost)  month_sumary_margin
    FROM    (
             --------------------------------------
             -- ���ѐU�ցi���㋒�_�j
             --------------------------------------
             SELECT  /*+ LEADING(xtca) USE_NL(xca xsti) */
                     TO_CHAR(xsti.selling_date,'YYYYMM')     year_month
                    ,TO_CHAR(xsti.selling_date,'MM')         month
                    ,xca.sale_base_code                      sale_base_code
                    ,xsti.item_code                          item_code
                    ,xsti.qty                                qty
                    ,xsti.selling_amt                        pure_amount
                    ,xsti.trading_cost                       trading_cost
             FROM    xxcsm_tmp_cust_accounts  xtca
                    ,xxcmm_cust_accounts      xca
                    ,xxcok_selling_trns_info  xsti
             WHERE   xca.sale_base_code              = xtca.account_number
               AND   (
                      (xca.rsv_sale_base_act_date IS NULL)
                      OR
                      (xca.rsv_sale_base_act_date <> gt_start_date)
                     )
               AND   xsti.cust_code                  = xca.customer_code
               AND   xsti.selling_date  >= ADD_MONTHS(gt_start_date,-24)
               AND   xsti.selling_date   < gt_start_date
               AND   xsti.selling_date   < cd_process_date
               AND   (
                      (xsti.report_decision_flag   = cv_flg_on)
                      OR
                      (    (xsti.selling_date = (cd_process_date-1))
                       AND (xsti.report_decision_flag     = cv_flg_off)
                       AND (xsti.correction_flag          = cv_flg_off)
                      )
                     )
               AND   (
                      (gv_location_cd IS NULL)
                      OR
                      (    (gv_location_cd IS NOT NULL)
                       AND (xca.sale_base_code = gv_location_cd)
                      )
                     )
               AND   (
                      (gv_item_no IS NULL)
                      OR
                      (
                       (gv_item_no IS NOT NULL)
                       AND
                       (xsti.item_code = gv_item_no)
                      )
                     )
               AND   EXISTS (
                       -- �l���p�i�ڈȊO
                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
                               'X'
                       FROM    ic_item_mst_b           iimb
                              ,fnd_lookup_values_vl    flvv
                              ,xxcmm_system_items_b    xsib
                              ,gmi_item_categories     gic
                              ,mtl_categories_b        mcb
                              ,mtl_category_sets_b     mcsb
                              ,fnd_id_flex_structures  fifs
                              ,xxcsm_item_group_1_nm_v   xig1v    --���i�Q1������
                       WHERE   iimb.item_no                           = xsti.item_code
                         AND   flvv.lookup_type                       = cv_lookup_type_02
                         AND   flvv.enabled_flag                      = cv_flg_y
                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                                          AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.attribute3                        = cv_flg_y
                         AND   xsib.item_code                         = iimb.item_no
                         AND   xsib.item_status                       = flvv.lookup_code
                         AND   gic.item_id                            = iimb.item_id
                         AND   mcb.category_id                        = gic.category_id
                         AND   mcb.enabled_flag                       = cv_flg_y
                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
                         AND   mcb.segment1                          <> gv_discount_cd
                         AND   mcsb.category_set_id                   = gic.category_set_id
                         AND   mcsb.structure_id                      = mcb.structure_id
                         AND   fifs.application_id                    = cn_inv_application_id
                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
                         AND   mcsb.structure_id                      = fifs.id_flex_num
                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
                         AND   ROWNUM                                 = 1
                     )
               AND   NOT EXISTS (
                       -- ����i�ڂ͑ΏۊO
                       SELECT  'X'
                       FROM    fnd_lookup_values_vl flvv
                       WHERE   flvv.lookup_type          = cv_sp_item_cd
                         AND   flvv.enabled_flag         = cv_flg_y
                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                             AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.lookup_code          = xsti.item_code
                         AND   ROWNUM                    = 1
                     )
             --------------------------------------
             -- ���ѐU�ցi�\�񔄏㋒�_�j
             --------------------------------------
             UNION ALL
             SELECT  /*+ LEADING(xtca) USE_NL(xca xsti) */
                     TO_CHAR(xsti.selling_date,'YYYYMM')     year_month
                    ,TO_CHAR(xsti.selling_date,'MM')         month
                    ,xca.rsv_sale_base_code                  sale_base_code
                    ,xsti.item_code                          item_code
                    ,xsti.qty                                qty
                    ,xsti.selling_amt                        pure_amount
                    ,xsti.trading_cost                       trading_cost
             FROM    xxcsm_tmp_cust_accounts  xtca
                    ,xxcmm_cust_accounts      xca
                    ,xxcok_selling_trns_info  xsti
             WHERE   xca.rsv_sale_base_code          = xtca.account_number
               AND   xca.rsv_sale_base_act_date      = gt_start_date
               AND   xsti.cust_code                  = xca.customer_code
               AND   xsti.selling_date  >= ADD_MONTHS(gt_start_date,-24)
               AND   xsti.selling_date   < gt_start_date
               AND   xsti.selling_date   < cd_process_date
               AND   (
                      (xsti.report_decision_flag   = cv_flg_on)
                      OR
                      (    (xsti.selling_date = (cd_process_date-1))
                       AND (xsti.report_decision_flag     = cv_flg_off)
                       AND (xsti.correction_flag          = cv_flg_off)
                      )
                     )
               AND   (
                      (gv_location_cd IS NULL)
                      OR
                      (    (gv_location_cd IS NOT NULL)
                       AND (xca.rsv_sale_base_code = gv_location_cd)
                      )
                     )
               AND   (
                      (gv_item_no IS NULL)
                      OR
                      (
                       (gv_item_no IS NOT NULL)
                       AND
                       (xsti.item_code = gv_item_no)
                      )
                     )
               AND   EXISTS (
                       -- �l���p�i�ڈȊO
                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
                               'X'
                       FROM    ic_item_mst_b           iimb
                              ,fnd_lookup_values_vl    flvv
                              ,xxcmm_system_items_b    xsib
                              ,gmi_item_categories     gic
                              ,mtl_categories_b        mcb
                              ,mtl_category_sets_b     mcsb
                              ,fnd_id_flex_structures  fifs
                              ,xxcsm_item_group_1_nm_v   xig1v    --���i�Q1������
                       WHERE   iimb.item_no                           = xsti.item_code
                         AND   flvv.lookup_type                       = cv_lookup_type_02
                         AND   flvv.enabled_flag                      = cv_flg_y
                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                                          AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.attribute3                        = cv_flg_y
                         AND   xsib.item_code                         = iimb.item_no
                         AND   xsib.item_status                       = flvv.lookup_code
                         AND   gic.item_id                            = iimb.item_id
                         AND   mcb.category_id                        = gic.category_id
                         AND   mcb.enabled_flag                       = cv_flg_y
                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
                         AND   mcb.segment1                          <> gv_discount_cd
                         AND   mcsb.category_set_id                   = gic.category_set_id
                         AND   mcsb.structure_id                      = mcb.structure_id
                         AND   fifs.application_id                    = cn_inv_application_id
                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
                         AND   mcsb.structure_id                      = fifs.id_flex_num
                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
                         AND   ROWNUM                                 = 1
                     )
               AND   NOT EXISTS (
                       -- ����i�ڂ͑ΏۊO
                       SELECT  'X'
                       FROM    fnd_lookup_values_vl flvv
                       WHERE   flvv.lookup_type          = cv_sp_item_cd
                         AND   flvv.enabled_flag         = cv_flg_y
                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                             AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.lookup_code          = xsti.item_code
                         AND   ROWNUM                    = 1
                     )
             --------------------------------------
             -- �̔����сi���㋒�_�j
             --------------------------------------
             UNION ALL
             SELECT  /*+ LEADING(xtca) USE_NL(xca xseh xsel) */
                     TO_CHAR(xseh.delivery_date,'YYYYMM')             year_month
                    ,TO_CHAR(xseh.delivery_date,'MM')                 month
                    ,xca.sale_base_code                               sale_base_code
                    ,xsel.item_code                                   item_code
                    ,xsel.standard_qty                                qty
                    ,xsel.pure_amount                                 pure_amount
                    ,(xsel.standard_qty * NVL(xsel.business_cost,0))  trading_cost
             FROM    xxcsm_tmp_cust_accounts  xtca
                    ,xxcmm_cust_accounts      xca
                    ,xxcos_sales_exp_headers  xseh
                    ,xxcos_sales_exp_lines    xsel
             WHERE   xca.sale_base_code              = xtca.account_number
               AND   (
                      (xca.rsv_sale_base_act_date IS NULL)
                      OR
                      (xca.rsv_sale_base_act_date <> gt_start_date)
                     )
               AND   xseh.ship_to_customer_code       = xca.customer_code
               AND   xseh.delivery_date  >= ADD_MONTHS(gt_start_date,-24)
               AND   xseh.delivery_date   < gt_start_date
               AND   xseh.delivery_date   < cd_process_date
               AND   xsel.sales_exp_header_id         = xseh.sales_exp_header_id
               AND   (
                      (gv_location_cd IS NULL)
                      OR
                      (    (gv_location_cd IS NOT NULL)
                       AND (xca.sale_base_code = gv_location_cd)
                      )
                     )
               AND   (
                      (gv_item_no IS NULL)
                      OR
                      (
                       (gv_item_no IS NOT NULL)
                       AND
                       (xsel.item_code = gv_item_no)
                      )
                     )
               AND   EXISTS (
                       -- �l���p�i�ڈȊO
                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
                               'X'
                       FROM    ic_item_mst_b           iimb
                              ,fnd_lookup_values_vl    flvv
                              ,xxcmm_system_items_b    xsib
                              ,gmi_item_categories     gic
                              ,mtl_categories_b        mcb
                              ,mtl_category_sets_b     mcsb
                              ,fnd_id_flex_structures  fifs
                              ,xxcsm_item_group_1_nm_v   xig1v    --���i�Q1������
                       WHERE   iimb.item_no                           = xsel.item_code
                         AND   flvv.lookup_type                       = cv_lookup_type_02
                         AND   flvv.enabled_flag                      = cv_flg_y
                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                                          AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.attribute3                        = cv_flg_y
                         AND   xsib.item_code                         = iimb.item_no
                         AND   xsib.item_status                       = flvv.lookup_code
                         AND   gic.item_id                            = iimb.item_id
                         AND   mcb.category_id                        = gic.category_id
                         AND   mcb.enabled_flag                       = cv_flg_y
                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
                         AND   mcb.segment1                          <> gv_discount_cd
                         AND   mcsb.category_set_id                   = gic.category_set_id
                         AND   mcsb.structure_id                      = mcb.structure_id
                         AND   fifs.application_id                    = cn_inv_application_id
                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
                         AND   mcsb.structure_id                      = fifs.id_flex_num
                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
                         AND   ROWNUM                                 = 1
                     )
               AND   NOT EXISTS (
                       -- ����i�ڂ͑ΏۊO
                       SELECT  'X'
                       FROM    fnd_lookup_values_vl flvv
                       WHERE   flvv.lookup_type          = cv_sp_item_cd
                         AND   flvv.enabled_flag         = cv_flg_y
                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                             AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.lookup_code          = xsel.item_code
                         AND   ROWNUM                    = 1
                     )
             --------------------------------------
             -- �̔����сi�\�񔄏㋒�_�j
             --------------------------------------
             UNION ALL
             SELECT  /*+ LEADING(xtca) USE_NL(xca xseh xsel) */
                     TO_CHAR(xseh.delivery_date,'YYYYMM')             year_month
                    ,TO_CHAR(xseh.delivery_date,'MM')                 month
                    ,xca.rsv_sale_base_code                           sale_base_code
                    ,xsel.item_code                                   item_code
                    ,xsel.standard_qty                                qty
                    ,xsel.pure_amount                                 pure_amount
                    ,(xsel.standard_qty * NVL(xsel.business_cost,0))  trading_cost
             FROM    xxcsm_tmp_cust_accounts  xtca
                    ,xxcmm_cust_accounts      xca
                    ,xxcos_sales_exp_headers  xseh
                    ,xxcos_sales_exp_lines    xsel
             WHERE   xca.rsv_sale_base_code           = xtca.account_number
               AND   xca.rsv_sale_base_act_date       = gt_start_date
               AND   xseh.ship_to_customer_code       = xca.customer_code
               AND   xseh.delivery_date  >= ADD_MONTHS(gt_start_date,-24)
               AND   xseh.delivery_date   < gt_start_date
               AND   xseh.delivery_date   < cd_process_date
               AND   xsel.sales_exp_header_id         = xseh.sales_exp_header_id
               AND   (
                      (gv_location_cd IS NULL)
                      OR
                      (    (gv_location_cd IS NOT NULL)
                       AND (xca.rsv_sale_base_code = gv_location_cd)
                      )
                     )
               AND   (
                      (gv_item_no IS NULL)
                      OR
                      (
                       (gv_item_no IS NOT NULL)
                       AND
                       (xsel.item_code = gv_item_no)
                      )
                     )
               AND   EXISTS (
                       -- �l���p�i�ڈȊO
                       SELECT  /*+ LEADING(iimb) USE_NL(iimb gic mcb mcsb fifs) */
                               'X'
                       FROM    ic_item_mst_b           iimb
                              ,fnd_lookup_values_vl    flvv
                              ,xxcmm_system_items_b    xsib
                              ,gmi_item_categories     gic
                              ,mtl_categories_b        mcb
                              ,mtl_category_sets_b     mcsb
                              ,fnd_id_flex_structures  fifs
                              ,xxcsm_item_group_1_nm_v   xig1v    --���i�Q1������
                       WHERE   iimb.item_no                           = xsel.item_code
                         AND   flvv.lookup_type                       = cv_lookup_type_02
                         AND   flvv.enabled_flag                      = cv_flg_y
                         AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                                          AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.attribute3                        = cv_flg_y
                         AND   xsib.item_code                         = iimb.item_no
                         AND   xsib.item_status                       = flvv.lookup_code
                         AND   gic.item_id                            = iimb.item_id
                         AND   mcb.category_id                        = gic.category_id
                         AND   mcb.enabled_flag                       = cv_flg_y
                         AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
                         AND   mcb.segment1                          <> gv_discount_cd
                         AND   mcsb.category_set_id                   = gic.category_set_id
                         AND   mcsb.structure_id                      = mcb.structure_id
                         AND   fifs.application_id                    = cn_inv_application_id
                         AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
                         AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
                         AND   mcsb.structure_id                      = fifs.id_flex_num
                         AND   mcb.segment1                           LIKE REPLACE(xig1v.item_group_cd,'*','_')
                         AND   ROWNUM                                 = 1
                     )
               AND   NOT EXISTS (
                       -- ����i�ڂ͑ΏۊO
                       SELECT  'X'
                       FROM    fnd_lookup_values_vl flvv
                       WHERE   flvv.lookup_type          = cv_sp_item_cd
                         AND   flvv.enabled_flag         = cv_flg_y
                         AND   cd_process_date           BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                             AND NVL(flvv.end_date_active,cd_process_date)
                         AND   flvv.lookup_code          = xsel.item_code
                         AND   ROWNUM                    = 1
                     )
             ) inn_v
    GROUP BY inn_v.year_month
            ,inn_v.month
            ,inn_v.sale_base_code
            ,inn_v.item_code
    ORDER BY inn_v.sale_base_code
            ,inn_v.item_code
            ,inn_v.year_month
    ;
--��������������������������������������������������������������������������������������������������������������������������������
--//+UPD END 2009/08/03 0000479 T.Tsukino
--//+UPD END   2009/06/03 T1_1174 M.Ohtsuki
    --�e�[�u���^���`
    TYPE sales_result_type IS TABLE OF sales_result_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    --�e�[�u���^�ϐ����`
    sales_result_cur_rec  sales_result_type;
--
    --*** �Ώەi�ڂ̏��i�Q�R�[�h�A�������̒��o ***
    CURSOR group4v_start_date_cur(
                                 it_item_no  xxcsm_item_plan_result.item_no%TYPE
                                 )
    IS
--//+UPD START 2009/08/03 0000479 T.Tsukino
--//+DEL START 2009/08/03 0000479 T.Tsukino
--��������������������������������������������������������������������������������������������������������������������������������
--      SELECT   xcg4v.group4_cd           group_cd                  --���i�Q�R�[�h(4��)
--              ,xcg4v.now_business_cost   now_business_cost         --�c�ƌ���
--              ,iimb.item_no              opm_item_no               --OPM�i�ڃ}�X�^�i�ڃR�[�h
--              ,iimb.attribute13          start_day                 --������
--      FROM     xxcsm_commodity_group4_v  xcg4v                     --���i�Q�S�r���[
--              ,ic_item_mst_b             iimb                      --OPM�i�ڃ}�X�^
--      WHERE   xcg4v.item_cd(+) = iimb.item_no
--      AND     iimb.item_no = it_item_no                         --OPM�i�ڃ}�X�^�̕i�ڃR�[�h�R�t��
--��������������������������������������������������������������������������������������������������������������������������������
--//+DEL END 2009/08/03 0000479 T.Tsukino
      SELECT  /*+ LEADING(iimb) USE_NL(flvv xsib gic mcb mcsb fifs) */
              mcb.segment1                 group_cd
             ,NVL(iimb.attribute8,0)       now_business_cost
             ,iimb.item_no                 opm_item_no
             ,iimb.attribute13             start_day
      FROM    ic_item_mst_b           iimb
             ,fnd_lookup_values_vl    flvv
             ,xxcmm_system_items_b    xsib
             ,gmi_item_categories     gic
             ,mtl_categories_b        mcb
             ,mtl_category_sets_b     mcsb
             ,fnd_id_flex_structures  fifs
      WHERE   iimb.item_no                           = it_item_no
        AND   flvv.lookup_type                       = cv_lookup_type_02
        AND   flvv.enabled_flag                      = cv_flg_y
        AND   cd_process_date                        BETWEEN NVL(flvv.start_date_active,cd_process_date)
                                                         AND NVL(flvv.end_date_active,cd_process_date)
        AND   flvv.attribute3                        = cv_flg_y
        AND   xsib.item_code                         = iimb.item_no
        AND   xsib.item_status                       = flvv.lookup_code
        AND   gic.item_id                            = iimb.item_id
        AND   mcb.category_id                        = gic.category_id
        AND   mcb.enabled_flag                       = cv_flg_y
        AND   NVL(mcb.disable_date,cd_process_date) <= cd_process_date
        AND   mcsb.category_set_id                   = gic.category_set_id
        AND   mcsb.structure_id                      = mcb.structure_id
        AND   fifs.application_id                    = cn_inv_application_id
        AND   fifs.id_flex_code                      = cv_id_flex_code_mcat
        AND   fifs.id_flex_structure_code            = cv_id_flex_str_code_sgum
        AND   mcsb.structure_id                      = fifs.id_flex_num
--//+UPD END 2009/08/03 0000479 T.Tsukino
    ;
    group4v_start_date_cur_rec group4v_start_date_cur%ROWTYPE;
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


--���[�J���ϐ�������
    lv_location_cd     := NULL;         --���_�R�[�h
    lv_item_no         := NULL;         --�i�ڃR�[�h
    lv_location_pre    := NULL;         --�O���_�R�[�h
    lv_item_no_pre     := NULL;         --�O�i�ڃR�[�h
    lv_group_cd        := NULL;         --���i�Q�R�[�h
    lv_opm_item_no     := NULL;         --OPM�i�ڃ}�X�^�i�ڃR�[�h
    lv_start_date      := NULL;         --������
    ln_amount          := 0;            --���ʌ��v
    ln_sales_budget    := 0;            --���㌎�v
    ln_margin_you      := 0;            --�e���v�Z�o�p�f�[�^
    ln_margin          := 0;            --�e���v
    ln_result_cnt      := 0;            --�̔����ђ��o����
    lb_skip_flg        := FALSE;        --�X�L�b�v�t���O
    lb_group_skip_flg  := FALSE;        --���i�Q�R�[�h�擾�ł��Ȃ��Ƃ��A�X�L�b�v�t���O
    opm_item_count     := 0;
    --�R���J�����g�N���̎������A���f�[�^��邩���f���܂��B
    IF cd_process_date >= gt_start_date THEN
    --�R���J�����g�N���͗\�Z�N�x�J�n���ȍ~�̏ꍇ�A���f�[�^�����Ȃ��B
      lb_create_data := FALSE;
    ELSE
    --�R���J�����g�N���͗\�Z�N�x�J�n���ȑO�̏ꍇ�A���f�[�^�����B
      lb_create_data := TRUE;
    END IF;
    
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN sales_result_cur;
      FETCH sales_result_cur BULK COLLECT INTO sales_result_cur_rec;
      --�Ώی���
      gn_target_cnt := sales_result_cur_rec.COUNT;
      
      FOR i IN 1..sales_result_cur_rec.COUNT  LOOP
      EXIT WHEN gn_target_cnt = 0;
        BEGIN
          ln_year_month    := sales_result_cur_rec(i).year_month;                    --�N��
          ln_month_no      := sales_result_cur_rec(i).month;                         --��
          lv_location_cd   := sales_result_cur_rec(i).sale_base_code;                --���_�R�[�h
          lv_item_no       := sales_result_cur_rec(i).item_code;                     --�i�ڃR�[�h
          ln_amount        := sales_result_cur_rec(i).month_sumary_qty;              --���ʌ��v
          ln_sales_budget  := sales_result_cur_rec(i).month_sumary_pure_amount;      --���㌎�v
          ln_margin_you    := sales_result_cur_rec(i).month_sumary_margin;           --�e���v�Z�o�p�f�[�^
          --�e���v�̎Z�o
          ln_margin    := ln_sales_budget - ln_margin_you;                            --�e���v
--
          --�\�Z�N�x�ɃR���J�����g�N���̏ꍇ�A���f�[�^���쐬
          IF lb_skip_flg = FALSE AND lb_group_skip_flg = FALSE THEN
            IF lb_create_data THEN
              --�O�i�ڃf�[�^���C���T�[�g������A�O�i�ڃR�[�h�P�ʂŁA���f�[�^���쐬
              IF (lv_location_pre IS NOT NULL AND lv_location_pre <> lv_location_cd) OR
                  (lv_item_no_pre IS NOT NULL AND lv_item_no_pre <> lv_item_no) THEN
                -- ===================================
                -- ���f�[�^�쐬����(A-8)
                -- ===================================
                temp_data_make(
                              lv_location_pre,              -- �O���_�R�[�h
                              lv_item_no_pre,               -- �O�i�ڃR�[�h
                              lv_group_cd_pre,              -- �O���i�Q�R�[�h
                              lv_start_date_pre,            -- �O������
                              ln_discrete_cost_pre,         -- �O�c�ƌ���
                              lv_errbuf,                    -- �G���[�E���b�Z�[�W
                              lv_retcode,                   -- ���^�[���E�R�[�h
                              lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W
                -- ��O����
                IF (lv_retcode <> cv_status_normal) THEN
                  --(�G���[����)
                  RAISE global_api_expt;
                END IF;
              END IF;
            END IF;
          END IF;
          --��i�ږڂ̎��A�i�ڃR�[�h���ς�����Ƃ�
          IF (lv_location_pre IS NULL OR lv_location_pre <> lv_location_cd) OR 
              (lv_item_no_pre IS NULL OR lv_item_no_pre <> lv_item_no) THEN
            SAVEPOINT item_no_point;
            lb_skip_flg := FALSE;
            lb_group_skip_flg := FALSE;
            -- ===========================================
            -- ���i�v��p�̔����уe�[�u�����b�N����(A-9)
            -- ===========================================
            lock_plan_result(
                            lv_location_cd,                     -- ���_�R�[�h
                            lv_item_no,                         -- �i�ڃR�[�h
                            lv_errbuf,                          -- �G���[�E���b�Z�[�W
                            lv_retcode,                         -- ���^�[���E�R�[�h
                            lv_errmsg );
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE item_skip_expt;
            END IF;
--
            -- ===========================================
            -- ���i�v��p�̔����уe�[�u���폜����(A-9)
            -- ===========================================
            delete_plan_result(
                            lv_location_cd,                    -- ���_�R�[�h
                            lv_item_no,                        -- �i�ڃR�[�h
                            lv_errbuf,                         -- �G���[�E���b�Z�[�W
                            lv_retcode,                        -- ���^�[���E�R�[�h
                            lv_errmsg );
            -- ��O����
            IF (lv_retcode <> cv_status_normal) THEN
              --(�G���[����)
              RAISE global_api_others_expt;
            END IF;
            --�Ώەi�ڂ̏��i�Q�R�[�h�A�������𒊏o
            OPEN group4v_start_date_cur(lv_item_no);
              FETCH group4v_start_date_cur INTO group4v_start_date_cur_rec;
              lv_group_cd      := group4v_start_date_cur_rec.group_cd;             --���i�Q�R�[�h(4��)
              ln_discrete_cost := group4v_start_date_cur_rec.now_business_cost;    --�c�ƌ���
              lv_opm_item_no   := group4v_start_date_cur_rec.opm_item_no;          --OPM�i�ڃR�[�h
              lv_start_date    := group4v_start_date_cur_rec.start_day;            --������
              IF group4v_start_date_cur%NOTFOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_xxcsm
                                                 ,iv_name         => cv_chk_err_00053
                                                 ,iv_token_name1  => cv_tkn_cd_item_cd
                                                 ,iv_token_value1 => lv_item_no
                                                 );
                lv_errbuf := lv_errmsg;
                RAISE item_skip_expt;
              END IF;
              IF lv_opm_item_no IS NOT NULL AND lv_start_date IS NULL THEN
              --�������擾�G���[���b�Z�[�W
                lv_errmsg := xxccp_common_pkg.get_msg(
                                                  iv_application  => cv_xxcsm
                                                 ,iv_name         => cv_chk_err_00110
                                                 ,iv_token_name1  => cv_tkn_cd_deal
                                                 ,iv_token_value1 => lv_group_cd
                                                 ,iv_token_name2  => cv_tkn_cd_item_cd
                                                 ,iv_token_value2 => lv_item_no
                                                 );
                lv_errbuf := lv_errmsg;
                RAISE item_skip_expt;
              END IF;
              --���i�Q�R�[�h���擾�ł��Ȃ��ꍇ�A�i�ڃR�[�h�P�ʂŃX�L�b�v���܂��B
              IF lv_group_cd IS NULL THEN 
                RAISE group_cd_expt;
              END IF;
            CLOSE group4v_start_date_cur; 
            --���[�N�e�[�u���Ƀf�[�^��o�^
            INSERT INTO xxcsm_tmp_sales_result xtsr(    -- �̔����у��[�N�e�[�u��
               xtsr.location_cd                         -- ���_�R�[�h
              ,xtsr.item_no)                            -- �i�ڃR�[�h
            VALUES(
               lv_location_cd                          -- ���_�R�[�h
              ,lv_item_no);                             -- �i�ڃR�[�h
            
          END IF;
--
          --�G���[�������́A�i�ڃR�[�h�P�ʂŃX�L�b�v������B
          IF lb_skip_flg THEN
            RAISE item_skip_expt;
          END IF;
          IF lb_group_skip_flg THEN
            RAISE group_cd_expt;
          END IF;
          --�Ώ۔N�x�Z�o
          IF ln_year_month < TO_NUMBER(TO_CHAR(ADD_MONTHS(gt_start_date,-12),'YYYYMM')) THEN
            ln_subject_year := gt_active_year - 2;
          ELSE
            ln_subject_year := gt_active_year - 1;
          END IF;
          -- ========================================
          -- ���i�v��p�̔����уe�[�u���o�^����(A-9)
          -- ========================================
          insert_plan_result(
                             ln_subject_year              -- �Ώ۔N�x
                            ,ln_year_month                -- �N��
                            ,ln_month_no                  -- ��
                            ,lv_location_cd               -- ���_�R�[�h
                            ,lv_item_no                   -- ���i�R�[�h
                            ,lv_group_cd                  -- ���i�Q�R�[
                            ,ln_amount                    -- ����
                            ,ln_sales_budget              -- ������z
                            ,ln_margin                    -- �e���v
                            ,lv_errbuf                    -- �G���[�E���b�Z�[�W
                            ,lv_retcode                   -- ���^�[���E�R�[�h
                            ,lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_others_expt;
          END IF;
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          WHEN item_skip_expt THEN
            --�G���[�����f�[�^�̂�
            IF group4v_start_date_cur%ISOPEN THEN
              CLOSE group4v_start_date_cur;
            END IF;
            IF (lb_skip_flg = FALSE) THEN
              fnd_file.put_line(
                              which  => FND_FILE.LOG
                             ,buff   => lv_errbuf
                             );
              fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_errmsg
                             );
              lb_skip_flg := TRUE;
              ROLLBACK TO item_no_point;
            END IF;
            gn_error_cnt := gn_error_cnt + 1;
          --���i�Q�R�[�h�擾��O
          WHEN group_cd_expt THEN
            IF group4v_start_date_cur%ISOPEN THEN
              CLOSE group4v_start_date_cur;
            END IF;
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_group_skip_flg := TRUE;
        END;
        --�O���R�[�h�ۑ�
        lv_item_no_pre        := lv_item_no;         --�i�ڃR�[�h�ۑ�
        lv_location_pre       := lv_location_cd;     --���_�R�[�h�ۑ�
        lv_group_cd_pre       := lv_group_cd;        --���i�Q�R�[�h�ۑ�
        lv_start_date_pre     := lv_start_date;      --�������ۑ�
        ln_discrete_cost_pre  := ln_discrete_cost;   --�c�ƌ����ۑ�
      END LOOP;
--
    --�Ώۃf�[�^�����G���[����
    IF gn_target_cnt = 0 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcsm
                                            ,iv_name         => cv_chk_err_00085
                                            ,iv_token_name1  => cv_tkn_cd_year
                                            ,iv_token_value1 => gt_active_year
                                            );
      lv_errbuf := lv_errmsg;
      fnd_file.put_line(
                              which  => FND_FILE.OUTPUT
                             ,buff   => lv_errbuf
                             );
      RAISE no_date_expt;
    END IF;
      --�Ō�̕i�ڃR�[�h�ɑ΂��āA���f�[�^���쐬
      --�\�Z�N�x�ɃR���J�����g�N���̏ꍇ�A���f�[�^���쐬
      IF lb_skip_flg = FALSE AND lb_group_skip_flg = FALSE THEN
        IF lb_create_data THEN
          -- ===================================
          -- ���f�[�^�쐬����(A-)
          -- ===================================
          temp_data_make(
                         lv_location_pre,                   -- �O���_�R�[�h
                         lv_item_no_pre,                    -- �O�i�ڃR�[�h
                         lv_group_cd_pre,                   -- �O���i�Q�R�[�h
                         lv_start_date_pre,                 -- �O������
                         ln_discrete_cost_pre,              -- �O�c�ƌ���
                         lv_errbuf,                         -- �G���[�E���b�Z�[�W
                         lv_retcode,                        -- ���^�[���E�R�[�h
                         lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W
          -- ��O����
          IF (lv_retcode <> cv_status_normal) THEN
            --(�G���[����)
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    CLOSE sales_result_cur;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�����G���[ ***
     WHEN no_date_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_normal;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sales_result_select;
--
  /***********************************************************************************
   * Procedure Name   : delete_no_result
   * Description      : ���_�J�ڂ̊����f�[�^�폜(A-)
   ***********************************************************************************/
  PROCEDURE delete_no_result(
    ov_errbuf           OUT  NOCOPY VARCHAR2,                -- �G���[�E���b�Z�[�W
    ov_retcode          OUT  NOCOPY VARCHAR2,                -- ���^�[���E�R�[�h
    ov_errmsg           OUT  NOCOPY VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_no_result'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   #################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   ############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �폜����
    DELETE xxcsm_item_plan_result xipr                         --���i�v��p�̔����уe�[�u��
    WHERE  NOT EXISTS ( SELECT 'X'
                        FROM   xxcsm_tmp_sales_result   xtsr
                        WHERE  xtsr.location_cd = xipr.location_cd
                        AND    xtsr.item_no = xipr.item_no
                      )
    AND    xipr.subject_year >= (gt_active_year - 2)
--//+ADD START 2009/02/23 CT057 S.Son
    AND    xipr.location_cd = NVL(gv_location_cd,xipr.location_cd)
    AND    xipr.item_no     = NVL(gv_item_no,xipr.item_no)
    AND    xipr.location_cd IN (SELECT  xtca.account_number
                                FROM    xxcsm_tmp_cust_accounts   xtca                              --���㋒�_�R�[�h=�ڋq�R�[�h
                                WHERE   xtca.cust_account_id = TO_NUMBER(gv_parallel_value_no)      --���_��ID�ɂăp������
                               );
--//+ADD END 2009/02/23 CT057 S.Son
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ############################################
--
  END delete_no_result;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W 
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';          -- �v���O������
    
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                     VARCHAR2(5000);                                 --�G���[�E���b�Z�[�W
    lv_retcode                    VARCHAR2(1);                                    --���^�[���E�R�[�h
    lv_errmsg                     VARCHAR2(5000);                                 --���[�U�[�E�G���[�E���b�Z�[�W

    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================

--
--###########################  �Œ蕔 END   ####################################
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
    gn_warn_cnt   := 0;
    gn_temp_normal_cnt := 0;                    --���f�[�^�쐬��������
    gn_temp_error_cnt  := 0;                    --���f�[�^�쐬�G���[����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
          lv_errbuf         -- �G���[�E���b�Z�[�W
         ,lv_retcode        -- ���^�[���E�R�[�h
         ,lv_errmsg );      -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �̔����ђ��o����(A-2)
    -- ===============================
    sales_result_select(
                        lv_errbuf,                         -- �G���[�E���b�Z�[�W
                        lv_retcode,                        -- ���^�[���E�R�[�h
                        lv_errmsg );                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ���_�J�ڊ����f�[�^�폜(A-)
    -- ===============================
    delete_no_result(
          lv_errbuf         -- �G���[�E���b�Z�[�W
         ,lv_retcode        -- ���^�[���E�R�[�h
         ,lv_errmsg );      -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ��O����
    IF (lv_retcode <> cv_status_normal) THEN
      --(�G���[����)
      RAISE global_api_expt;
    END IF;
--
    IF gn_error_cnt > 0 OR gn_temp_error_cnt > 0 THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2,      -- �G���[�E���b�Z�[�W
    retcode                  OUT NOCOPY VARCHAR2,      -- ���^�[���E�R�[�h
    iv_parallel_value_no     IN  VARCHAR2,             -- �p�������ԍ�
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    iv_parallel_cnt          IN  VARCHAR2,             -- �p��������
--//+DEL END 2009/08/03 0000479 T.Tsukino
    iv_location_cd           IN  VARCHAR2,             -- ���_�R�[�h
    iv_item_no               IN  VARCHAR2              -- �i�ڃR�[�h
      )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_temp_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00115'; -- ���f�[�^�쐬�I�����b�Z�[�W
    cv_temp_success_cnt_token  CONSTANT VARCHAR2(50)  := 'TEMP_SUCCESS_COUNT';--���f�[�^�쐬��������
    cv_temp_error_cnt_token    CONSTANT VARCHAR2(50)  := 'TEMP_ERROR_COUNT'; -- ���f�[�^�쐬�G���[����

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
       ov_retcode => lv_retcode
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
    --���̓p�����[�^
    gv_parallel_value_no := iv_parallel_value_no;       --�p�������ԍ�
--//+DEL START 2009/08/03 0000479 T.Tsukino
--    gv_parallel_cnt      := iv_parallel_cnt;            --�p��������
--//+DEL END 2009/08/03 0000479 T.Tsukino
    gv_location_cd       := iv_location_cd;             --���_�R�[�h
    gv_item_no           := iv_item_no;                 --�i�ڃR�[�h
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W 
      ,lv_retcode  -- ���^�[���E�R�[�h  
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_xxcsm
                                                ,iv_name         => cv_msg_00111
                                               );
      END IF;
      
    --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
      gn_temp_normal_cnt := 0;
      gn_temp_error_cnt := 0;
      
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    --���f�[�^���������o��
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm
                    ,iv_name         => cv_temp_rec_msg
                    ,iv_token_name1  => cv_temp_success_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_temp_normal_cnt)
                    ,iv_token_name2  => cv_temp_error_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_temp_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSM002A01C;
/