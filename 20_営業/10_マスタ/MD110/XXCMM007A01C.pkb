CREATE OR REPLACE PACKAGE BODY XXCMM007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM007A01C(body)
 * Description      : �ڋq�̕W����ʂ�胁���e�i���X���ꂽ���́E�Z�������A
 *                  : �p�[�e�B�A�h�I���}�X�^�֔��f���A���e�̓������s���܂��B
 * MD.050           : ���Y�ڋq��񓯊� MD050_CMM_005_A04
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_parties_data       �����Ώۃf�[�^���o(A-2)
 *  chk_linkage_item       �A�g���ڃ`�F�b�N(A-3)
 *  upd_xxcmn_parties      �p�[�e�B�A�h�I���X�V(A-4)
 *  ins_xxcmn_parties      �p�[�e�B�A�h�I���o�^(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/18    1.0   Masayuki.Sano    �V�K�쐬
 *  2009/02/26    1.1   Masayuki.Sano    �����e�X�g����s���Ή�
 *  2010/02/15    1.2   Yutaka.Kuboshima ��QE_�{�ғ�_01419 �����e�[�u���Ƀp�[�e�B�T�C�g�A�h�I����ǉ�
 *                                                          �p�[�e�B�A�h�I���̏����l��ύX
 *  2010/02/18    1.3   Yutaka.Kuboshima ��QE_�{�ғ�_01419 PT�Ή�
 *  2010/02/23    1.4   Yutaka.Kuboshima ��QE_�{�ғ�_01419 �A�g���ڃ`�F�b�N�G���[���ł�����I������悤�C��
 *  2010/05/28    1.5   Shigeto.Niki     ��QE_�{�ғ�_02876 �ڋq���̂܂��͏Z����񂪕ύX���ꂽ�ꍇ�ɍX�V����悤�C��
 *                                                          �c�Ƒg�DID���C��
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  no_output_data_expt       EXCEPTION;  -- �Ώۃf�[�^������O
  size_over_expt            EXCEPTION;  -- ���Y�A�g���ڃT�C�Y�I�[�o�[��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCMM007A01C';  -- �p�b�P�[�W��
  -- �� �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30) := 'XXCMM';      -- �}�X�^
  cv_app_name_xxccp   CONSTANT VARCHAR2(30) := 'XXCCP';      -- ���ʁEIF
  -- �� �J�X�^���E�v���t�@�C���E�I�v�V����
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  cv_pro_init01       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT01';
--                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����������l
--  cv_pro_init03       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT03';
--                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�U�փO���[�v�����l
--  cv_pro_init04       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT04';
--                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����u���b�N�����l
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  cv_pro_init05       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT05';
                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���_�啪�ޏ����l
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  cv_pro_init06       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT16';
--                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�h�����N�^���U�֊�����l
--  cv_pro_init07       CONSTANT VARCHAR2(50) := 'XXCMN_830001F_INIT17';
--                                 -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���[�t�^���U�֊�����l 
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  cv_pro_sys_ctrl_cal CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';
                                 -- �V�X�e���ғ����J�����_�R�[�h��`�v���t�@�C��
  -- �� ���b�Z�[�W�E�R�[�h�i�G���[/�x���j
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00305';  -- ���Ԏw��G���[
  cv_msg_00015        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00015';  -- �g�DID�擾�G���[
  cv_msg_00008        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_00702        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00702';  -- ���Y�A�g���ڃT�C�Y�x�����b�Z�[�W
  cv_msg_00700        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00700';  -- �p�[�e�B�A�h�I���X�V�G���[���b�Z�[�W
  cv_msg_00701        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00701';  -- �p�[�e�B�A�h�I���o�^�G���[���b�Z�[�W
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';  -- �V�X�e���G���[
-- 2009/02/26 ADD by M.Sano End
  -- �� ���b�Z�[�W�E�R�[�h�i�R���J�����g�E�o�́j
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';  -- ���̓p�����[�^���b�Z�[�W
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- �Ώۃf�[�^����
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_warn_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  -- �� �g�[�N��
  cv_tok_ng_profile   CONSTANT VARCHAR2(20) := 'NG_PROFILE';    -- �v���t�@�C����
  cv_tok_ng_ou_name   CONSTANT VARCHAR2(20) := 'NG_OU_NAME';    -- �g�D��`��
  cv_tok_ng_table     CONSTANT VARCHAR2(20) := 'NG_TABLE';      -- �G���[�e�[�u����
  cv_tok_cust_cd      CONSTANT VARCHAR2(20) := 'CUST_CD';       -- �ڋq�R�[�h
  cv_tok_party_id     CONSTANT VARCHAR2(20) := 'PARTY_ID';      -- �p�[�e�BID
  cv_tok_col_name     CONSTANT VARCHAR2(20) := 'COL_NAME';      -- �J��������
  cv_tok_col_size     CONSTANT VARCHAR2(20) := 'COL_SIZE';      -- �J��������
  cv_tok_data_size    CONSTANT VARCHAR2(20) := 'DATA_SIZE';     -- �擾�f�[�^�̃T�C�Y
  cv_tok_data_val     CONSTANT VARCHAR2(20) := 'DATA_VAL';      -- �擾�e�[�^�̒l���e
  cv_tok_count        CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tok_param        CONSTANT VARCHAR2(20) := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(20) := 'VALUE';
  -- �� �g�[�N���l
  cv_tvl_sys_ctrl_cal CONSTANT VARCHAR2(80) := 'XXCMM:�ڋq�A�h�I���@�\�p�V�X�e���ғ����J�����_�R�[�h�l';
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  cv_tvl_pro_init01   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����������l';
--  cv_tvl_pro_init03   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�U�փO���[�v�����l';
--  cv_tvl_pro_init04   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����u���b�N�����l';
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  cv_tvl_pro_init05   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���_�啪�ޏ����l';
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  cv_tvl_pro_init06   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�h�����N�^���U�֊�����l';
--  cv_tvl_pro_init07   CONSTANT VARCHAR2(80) := 'XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���[�t�^���U�֊�����l';
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  cv_tvl_sales_ou     CONSTANT VARCHAR2(20) := 'SALES-OU';
  cv_tvl_itoe_ou_mfg  CONSTANT VARCHAR2(20) := 'ITOE-OU-MFG';
  cv_tvl_update_from  CONSTANT VARCHAR2(20) := '������(From)';
  cv_tvl_update_to    CONSTANT VARCHAR2(20) := '������(To)  ';
  cv_tvl_auto_st      CONSTANT VARCHAR2(20) := '[]:�����擾�l[';   -- �ݶ��ĥ���Ұ���_����(�J�n)
  cv_tvl_auto_en      CONSTANT VARCHAR2(1)  := ']';                -- �ݶ��ĥ���Ұ���_����(�I��)
  cv_tvl_para_st      CONSTANT VARCHAR2(1)  := '[';                -- �ݶ��ĥ���Ұ���(�J�n)
  cv_tvl_para_en      CONSTANT VARCHAR2(1)  := ']';                -- �ݶ��ĥ���Ұ���(�I��)
  cv_tvl_upd_tbl_name CONSTANT VARCHAR2(20) := '�p�[�e�B�A�h�I��'; -- �X�V�E�o�^�ΏۂƂȂ�e�[�u��
  -- �� �f�[�^�t�H�[�}�b�g
  cv_datetime_fmt     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt         CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add start by Shigeto.Niki
  cv_max_date         CONSTANT VARCHAR2(10) := '9999/12/31';       -- MAX���t
  cv_null             CONSTANT VARCHAR2(2)  := 'X';                -- NULL�̑�֕���
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add end by Shigeto.Niki  
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����}�X�^IF�o�́i���̋@�Ǘ��j���C�A�E�g
  TYPE xxcmn_parties_rtype IS RECORD
  (
     party_id                   hz_cust_accounts.party_id%TYPE             -- �p�[�e�BID
    ,account_number             hz_cust_accounts.account_number%TYPE       -- �ڋq�R�[�h
    ,party_name                 hz_parties.party_name%TYPE                 -- �ڋq����
    ,party_short_name           hz_cust_accounts.account_name%TYPE         -- �ڋq����
    ,party_name_alt             hz_parties.organization_name_phonetic%TYPE -- �ڋq�J�i��
    ,state                      hz_locations.state%TYPE                    -- �s���{��
    ,city                       hz_locations.city%TYPE                     -- �s�撬��
    ,address1                   hz_locations.address1%TYPE                 -- �Z���P
    ,address2                   hz_locations.address2%TYPE                 -- �Z���Q
    ,phone                      hz_locations.address_lines_phonetic%TYPE   -- �d�b�ԍ�
    ,fax                        hz_locations.address4%TYPE                 -- FAX�ԍ�
    ,postal_code                hz_locations.postal_code%TYPE              -- �X�֔ԍ�
    ,xxcmn_perties_active_flag  VARCHAR2(1)                                -- �p�[�e�B�A�h�I���L���t���O
  );
--
  -- �����}�X�^IF�o�́i���̋@�Ǘ��j���C�A�E�g �e�[�u���^�C�v
  TYPE xxcmn_parties_ttype IS TABLE OF xxcmn_parties_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^
  gv_in_proc_date_from        VARCHAR2(50);   -- ������(FROM)
  gv_in_proc_date_to          VARCHAR2(50);   -- ������(TO)
  -- �f�[�^�E�v���t�@�C��
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  gv_pro_init01     fnd_profile_option_values.profile_option_value%TYPE;  -- �����������l
--  gv_pro_init03     fnd_profile_option_values.profile_option_value%TYPE;  -- �U�փO���[�v�����l
--  gv_pro_init04     fnd_profile_option_values.profile_option_value%TYPE;  -- �����u���b�N�����l
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  gv_pro_init05     fnd_profile_option_values.profile_option_value%TYPE;  -- ���_�啪�ޏ����l
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--  gv_pro_init06     fnd_profile_option_values.profile_option_value%TYPE;  -- �h�����N�^���U�֊�����l
--  gv_pro_init07     fnd_profile_option_values.profile_option_value%TYPE;  -- ���[�t�^���U�֊�����l
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
  gv_sys_ctrl_cal   fnd_profile_option_values.profile_option_value%TYPE;  -- �J�����_�[�R�[�h
  -- �����̑ΏۂƂȂ�e�[�u��
  gt_parties_tab  xxcmn_parties_ttype;  -- �Z�����
  -- ���t�֘A
  gd_process_date             DATE;           -- �Ɩ����t
  gv_process_start_datetime   VARCHAR2(50);   -- �����J�n����(�t�H�[�}�b�g�FYYYY/MM/DD HH24:MI:SS)
  gd_proc_date_from           DATE;           -- ������(FROM) �����̓p�����[�^�̏����p
  gd_proc_date_to             DATE;           -- ������(TO)   �����̓p�����[�^�̏����p
  -- �f�[�^�̃L�[���
  gv_sal_org_id      hr_all_organization_units.organization_id%TYPE; -- �c�Ƒ��̑g�DID
  gv_mfg_org_id      hr_all_organization_units.organization_id%TYPE; -- ���Y���̑g�DID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    -- *** ���[�J���萔 ****
    cv_min_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    cv_max_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    -- *** ���[�J���ϐ� ***
    ld_prev_process_date DATE;          -- �O�Ɩ����t
    lv_proc_date_tmp     VARCHAR2(20);  -- ������(�ꎞ�i�[�p)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�P�D�����J�n�������擾���܂��B
    --==============================================================
    gv_process_start_datetime := TO_DATE(SYSDATE, cv_datetime_fmt);
--
    --=========================:=====================================
    --�Q�D�Ɩ����t���擾����B
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    --==============================================================
    --�R�D�O�Ɩ����t���擾���܂��B
    --==============================================================
    -- �J�����_�[�R�[�h���擾����B
    gv_sys_ctrl_cal    := FND_PROFILE.VALUE(cv_pro_sys_ctrl_cal);
    -- �J�����_�[�R�[�h���擾�ł��Ȃ��ꍇ�A�v���t�@�C���擾�G���[
    IF ( gv_sys_ctrl_cal IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_sys_ctrl_cal  -- �l      :�J�����_�[�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �O�Ɩ����t���擾����B
    ld_prev_process_date := xxccp_common_pkg2.get_working_day(
                              id_date          => gd_process_date
                             ,in_working_day   => -1
                             ,iv_calendar_code => gv_sys_ctrl_cal
                           );
--
    --==============================================================
    -- �S�D������(From)�Ə�����(To)�̐ݒ�
    --==============================================================
    -- ������(From)��"YYYY/MM/DD 00:00:00"�`���Ŏ擾
    -- (�p�����[�^�����͂̏ꍇ�A�O�Ɩ����t�̗������Z�b�g)
    IF ( gv_in_proc_date_from IS NULL ) THEN
      lv_proc_date_tmp := TO_CHAR(ld_prev_process_date + 1, cv_date_fmt) || cv_min_time;
    ELSE
      lv_proc_date_tmp := gv_in_proc_date_from || cv_min_time;
    END IF;
    -- �擾����������(From)����t�^�ɕϊ�
    gd_proc_date_from := TO_DATE(lv_proc_date_tmp, cv_datetime_fmt);
    -- ������(To)��"YYYY/MM/DD 23:59:59"�`���Ŏ擾
    -- (�p�����[�^�����͂̏ꍇ�A�Ɩ����t���Z�b�g)
    IF ( gv_in_proc_date_to IS NULL ) THEN
      lv_proc_date_tmp := TO_CHAR(gd_process_date, cv_date_fmt) || cv_max_time;
    ELSE
      lv_proc_date_tmp := gv_in_proc_date_to || cv_max_time;
    END IF;
    -- �擾����������(To)����t�^�ɕϊ�
    gd_proc_date_to := TO_DATE(lv_proc_date_tmp, cv_datetime_fmt);
--
    --==============================================================
    --�T�D�p�����[�^�`�F�b�N���s���܂��B
    --==============================================================
    -- "�ŏI�X�V��(From) > �ŏI�X�V��(To)"�̏ꍇ�A�p�����[�^�G���[
    IF ( gd_proc_date_from > gd_proc_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00031         -- �G���[:���Ԏw��G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�U�D�v���t�@�C���̎擾���s���܂��B
    --==============================================================
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����������l
--    gv_pro_init01    := FND_PROFILE.VALUE(cv_pro_init01);
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�U�փO���[�v�����l
--    gv_pro_init03    := FND_PROFILE.VALUE(cv_pro_init03);
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����u���b�N�����l
--    gv_pro_init04    := FND_PROFILE.VALUE(cv_pro_init04);
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���_�啪�ޏ����l
    gv_pro_init05    := FND_PROFILE.VALUE(cv_pro_init05);
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�h�����N�^���U�֊�����l
--    gv_pro_init06    := FND_PROFILE.VALUE(cv_pro_init06);
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���[�t�^���U�֊�����l 
--    gv_pro_init07    := FND_PROFILE.VALUE(cv_pro_init07);
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    --�V�D�v���t�@�C���擾���s���A�ȉ��̗�O�������s���܂��B
    --==============================================================
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����������l
--    IF ( gv_pro_init01 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
--                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init01    -- �l      :�����������l
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�U�փO���[�v�����l
--    IF ( gv_pro_init03 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
--                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init03    -- �l      :�U�փO���[�v�����l
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�����u���b�N�����l
--    IF ( gv_pro_init04 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
--                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init04    -- �l      :�����u���b�N�����l
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���_�啪�ޏ����l
    IF ( gv_pro_init05 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_pro_init05    -- �l      :���_�啪�ޏ����l
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_�h�����N�^���U�֊�����l
--    IF ( gv_pro_init06 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
--                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init06    -- �l      :�h�����N�^���U�֊�����l
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    -- XXCMN:�p�[�e�B�A�h�I���}�X�^�o�^���_���[�t�^���U�֊�����l
--    IF ( gv_pro_init07 IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
--                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
--                     ,iv_token_value1 => cv_tvl_pro_init07    -- �l      :���[�t�^���U�֊�����l
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    --�W�D�c�Ƒ��̑g�DID���擾���܂��B
    --==============================================================
    BEGIN
      SELECT haou.organization_id organization_id -- �c�Ƒg�DID
      INTO   gv_sal_org_id
      FROM   hr_all_organization_units haou       -- �l���g�D�}�X�^�e�[�u��
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--      WHERE  haou.name = 'SALES-OU'
      WHERE  haou.name = cv_tvl_sales_ou
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki
      AND    ROWNUM    = 1
      ;
    EXCEPTION
      -- �Ώۃf�[�^��������Ȃ������ꍇ
      WHEN NO_DATA_FOUND THEN
        gv_sal_org_id := NULL;
      -- ��L�ȊO�̏ꍇ
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --�X�D�c�Ƒg�DID�擾�m�F
    --==============================================================
    IF ( gv_sal_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00015         -- �G���[  :�g�DID�擾�G���[
                     ,iv_token_name1  => cv_tok_ng_ou_name    -- �g�[�N��:NG_OU_NAME
                     ,iv_token_value1 => cv_tvl_sales_ou      -- �l      :'SALES-OU'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�P�O�D���Y���̑g�DID���擾���܂��B
    --==============================================================
    BEGIN
      SELECT haou.organization_id organization_id -- ���Y�g�DID
      INTO   gv_mfg_org_id
      FROM   hr_all_organization_units haou       -- �l���g�D�}�X�^�e�[�u��
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--      WHERE  haou.name = 'ITOE-OU-MFG'
      WHERE  haou.name = cv_tvl_itoe_ou_mfg
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki
      AND    ROWNUM    = 1
      ;
    EXCEPTION
      -- �Ώۃf�[�^��������Ȃ������ꍇ
      WHEN NO_DATA_FOUND THEN
        gv_mfg_org_id := NULL;
      -- ��L�ȊO�̏ꍇ
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --�P�P�D���Y�g�DID�擾�m�F
    --==============================================================
    IF ( gv_mfg_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00015         -- �G���[  :�g�DID�擾�G���[
                     ,iv_token_name1  => cv_tok_ng_ou_name    -- �g�[�N��:NG_OU_NAME
                     ,iv_token_value1 => cv_tvl_itoe_ou_mfg   -- �l      :'ITOE-OU-MFG'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_parties_data
   * Description      : �����Ώۃf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_parties_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parties_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add start by Shigeto.Niki
    cv_flag_a                 CONSTANT VARCHAR2(1)  := 'A';   -- �L���t���OA
    cv_customer_class_cust    CONSTANT VARCHAR2(2)  := '10';  -- �ڋq�敪�F�ڋq
    cv_customer_class_base    CONSTANT VARCHAR2(2)  := '1';   -- �ڋq�敪�F���_
    cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';
    cv_flag_no                CONSTANT VARCHAR2(1)  := 'N';
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add end by Shigeto.Niki
--
    -- *** ���[�J���J�[�\��***
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
-- ���b�N�J�[�\���Ǝ擾�J�[�\������{�ɂ���
--    CURSOR parties_data_lock_cur(
--       id_proc_date_from DATE
--      ,id_proc_date_to   DATE
--      ,it_sal_org_id     hr_all_organization_units.organization_id%TYPE
--      ,it_mfg_org_id     hr_all_organization_units.organization_id%TYPE)
--    IS
--      SELECT xcp.party_id        AS party_id  -- (��)�p�[�e�BID
--      FROM   hz_cust_accounts       hca       -- (table)�ڋq�}�X�^�e�[�u��
--            ,hz_parties             hpt       -- (table)�p�[�e�B�e�[�u��
--            ,hz_party_sites         hps       -- (table)�p�[�e�B�T�C�g�e�[�u��
--            ,hz_cust_acct_sites_all hsa       -- (table)�ڋq���ݒn�e�[�u��
--            ,hz_locations           hlo       -- (table)�ڋq���Ə��e�[�u��
--            ,xxcmn_parties          xcp       -- (table)�p�[�e�B�A�h�I���e�[�u��
--      WHERE  hca.party_id        = hpt.party_id
--      AND    hca.party_id        = hps.party_id
--      AND    hca.cust_account_id = hsa.cust_account_id
--      AND    hps.party_site_id   = hsa.party_site_id
--      AND    hps.location_id     = hlo.location_id
--      AND    hca.party_id        = xcp.party_id
--      AND    hps.status          = 'A'                  -- (����)�p�[�e�B�T�C�g�e�[�u�����L��
--      AND    hca.customer_class_code IN ('1','10')      -- (����)���_�܂��͌ڋq
--      AND    hsa.org_id          = it_sal_org_id        -- (����)�g�D���c�Ƒg�D�ł���
--      AND    EXISTS( /* ���YOU��ۗL������� */
--               SELECT 'X'
--               FROM   hz_cust_acct_sites_all   hsa1 -- (table)�ڋq���ݒn�e�[�u��
--               WHERE  hsa1.cust_account_id = hca.cust_account_id
--               AND    hsa1.status          = 'A'
--               AND    hsa1.org_id          = it_mfg_org_id
--             )
--      AND    (   hca.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hsa.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hlo.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR EXISTS( 
--                   SELECT xcp1.party_id
--                   FROM   xxcmn_parties xcp1        -- (table)�p�[�e�B�A�h�I���e�[�u��
--                   WHERE  xcp1.party_id = hca.party_id
--                   AND    xcp1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_�{�ғ�_01419 add start by Yutaka.Kuboshima
--              -- �p�[�e�B�T�C�g�A�h�I���������e�[�u���ɒǉ�
--              OR EXISTS(
--                   SELECT xps1.party_site_id
--                   FROM   xxcmn_party_sites xps1
--                   WHERE  xps1.party_id = hca.party_id
--                   AND    xps1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_�{�ғ�_01419 add end by Yutaka.Kuboshima
--             )                                          -- (����)�ŏI�X�V����������(From�`To)�͈͓̔�
--      FOR UPDATE OF xcp.party_id  NOWAIT
--      ;
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
--
    -- �p�[�e�B�A�h�I���擾�J�[�\��
    CURSOR parties_data_cur(
       id_proc_date_from DATE
      ,id_proc_date_to   DATE
      ,it_sal_org_id     hr_all_organization_units.organization_id%TYPE
      ,it_mfg_org_id     hr_all_organization_units.organization_id%TYPE)
    IS
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify start by Yutaka.Kuboshima
--      SELECT hca.party_id                   AS party_id                   -- (��)�p�[�e�BID
      -- �q���g��̒ǉ�
      SELECT /*+ FIRST_ROWS LEADING(def hca) INDEX(hca HZ_CUST_ACCOUNTS_U1) */
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify end by Yutaka.Kuboshima
             hca.party_id                   AS party_id                   -- (��)�p�[�e�BID
            ,hca.account_number             AS account_number             -- (��)�ڋq�R�[�h
            ,hpt.party_name                 AS party_name                 -- (��)�ڋq����
            ,hca.account_name               AS party_short_name           -- (��)�ڋq����
            ,hpt.organization_name_phonetic AS party_name_alt             -- (��)�ڋq�J�i��
            ,hlo.state                      AS state                      -- (��)�s���{��
            ,hlo.city                       AS city                       -- (��)�s�撬��
            ,hlo.address1                   AS address1                   -- (��)�Z���P
            ,hlo.address2                   AS address2                   -- (��)�Z���Q
            ,hlo.address_lines_phonetic     AS phone                      -- (��)�d�b�ԍ�
            ,hlo.address4                   AS fax                        -- (��)FAX�ԍ�
            ,hlo.postal_code                AS postal_code                -- (��)�X�֔ԍ�
            ,CASE
               WHEN (
                 SELECT xcpt.party_id
                 FROM   xxcmn_parties  xcpt         -- (table)�p�[�e�B�A�h�I���e�[�u��
                 WHERE  xcpt.party_id = hca.party_id
                 AND    ROWNUM = 1
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--               ) IS NOT NULL THEN 'Y'
--               ELSE               'N'
               ) IS NOT NULL THEN cv_flag_yes
               ELSE               cv_flag_no
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki
             END                            AS xxcmn_perties_active_flag  -- (��)�p�[�e�B�A�h�I���L��
      FROM   hz_cust_accounts       hca             -- (table)�ڋq�}�X�^�e�[�u��
            ,hz_parties             hpt             -- (table)�p�[�e�B�e�[�u��
            ,hz_party_sites         hps             -- (table)�p�[�e�B�T�C�g�e�[�u��
            ,hz_cust_acct_sites_all hsa             -- (table)�ڋq���ݒn�e�[�u��
            ,hz_locations           hlo             -- (table)�ڋq���Ə��e�[�u��
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 add start by Yutaka.Kuboshima
            ,xxcmn_parties          xcp             -- (table)�p�[�e�B�A�h�I���e�[�u��
            ,(SELECT hca1.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca1
              WHERE  hca1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hcas2.cust_account_id   cust_account_id
              FROM   hz_cust_acct_sites_all hcas2
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--              WHERE  hcas2.org_id = 2190
              WHERE  hcas2.org_id = it_sal_org_id
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki
                AND  hcas2.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT /*+ USE_NL(hl3 hps3 hp3 hca3) */
                     hca3.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca3
                    ,hz_parties       hp3
                    ,hz_party_sites   hps3
                    ,hz_locations     hl3
              WHERE  hca3.party_id    = hp3.party_id
                AND  hp3.party_id     = hps3.party_id
                AND  hps3.location_id = hl3.location_id
                AND  hl3.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hca4.cust_account_id   cust_account_id
              FROM   hz_cust_accounts hca4
                    ,xxcmn_parties    xp4
              WHERE  hca4.party_id = xp4.party_id
                AND  xp4.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
              UNION
              SELECT hca5.cust_account_id   cust_account_id
              FROM   hz_cust_accounts  hca5
                    ,xxcmn_party_sites xps5
              WHERE  hca5.party_id = xps5.party_id
                AND  xps5.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
             ) def                                 -- �����Ώۃ��R�[�h
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 add end by Yutaka.Kuboshima
      WHERE  hca.party_id        = hpt.party_id
      AND    hca.party_id        = hps.party_id
      AND    hca.cust_account_id = hsa.cust_account_id
      AND    hps.party_site_id   = hsa.party_site_id
      AND    hps.location_id     = hlo.location_id
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--      AND    hps.status          = 'A'                  -- (����)�p�[�e�B�T�C�g�e�[�u�����L��
--      AND    hca.customer_class_code IN ('1','10')      -- (����)���_�܂��͌ڋq
      AND    hps.status          = cv_flag_a            -- (����)�p�[�e�B�T�C�g�e�[�u�����L��
      AND    hca.customer_class_code IN (cv_customer_class_base , cv_customer_class_cust)      -- (����)���_�܂��͌ڋq
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki    
      AND    hsa.org_id          = it_sal_org_id        -- (����)�g�D���c�Ƒg�D�ł���
      AND    EXISTS( /* ���YOU��ۗL������� */
               SELECT 'X'
               FROM   hz_cust_acct_sites_all   hsa1 -- (table)�ڋq���ݒn�e�[�u��
               WHERE  hsa1.cust_account_id = hca.cust_account_id
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki
--               AND    hsa1.status          = 'A'
               AND    hsa1.status          = cv_flag_a
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki
               AND    hsa1.org_id          = it_mfg_org_id
             )
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify start by Yutaka.Kuboshima
--      AND    (   hca.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hsa.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR hlo.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--              OR EXISTS( 
--                   SELECT xcp1.party_id
--                   FROM   xxcmn_parties xcp1        -- (table)�p�[�e�B�A�h�I���e�[�u��
--                   WHERE  xcp1.party_id = hca.party_id
--                   AND    xcp1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_�{�ғ�_01419 add start by Yutaka.Kuboshima
--              -- �p�[�e�B�T�C�g�A�h�I���������e�[�u���ɒǉ�
--              OR EXISTS(
--                   SELECT xps1.party_site_id
--                   FROM   xxcmn_party_sites xps1
--                   WHERE  xps1.party_id = hca.party_id
--                   AND    xps1.last_update_date BETWEEN id_proc_date_from AND id_proc_date_to
--                 )
---- 2010/02/15 Ver1.2 E_�{�ғ�_01419 add end by Yutaka.Kuboshima
--             )                                          -- (����)�ŏI�X�V����������(From�`To)�͈͓̔�
      AND    hps.party_id        = xcp.party_id(+)
      AND    hca.cust_account_id = def.cust_account_id
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add start by Shigeto.Niki
      -- �ڋq���̂܂��͏Z����񂪕s��v�̂��̂𒊏o
      AND   (NVL(xcp.party_name, cv_null)       <> NVL(SUBSTRB(hpt.party_name, 1, 60), cv_null)
       OR    NVL(xcp.party_short_name, cv_null) <> NVL(SUBSTRB(hca.account_name, 1, 20), cv_null)
       OR    NVL(xcp.party_name_alt, cv_null)   <> NVL(SUBSTRB(hpt.organization_name_phonetic, 1, 30), cv_null)
       OR    NVL(xcp.zip, cv_null)              <> NVL(SUBSTRB(hlo.postal_code, 1, 8), cv_null)
       OR    NVL(xcp.address_line1, cv_null)    <> NVL(SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2,  1, 30), cv_null)
       OR    NVL(xcp.address_line2, cv_null)    <> NVL(SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2, 31, 30), cv_null)
       OR    NVL(xcp.phone, cv_null)            <> NVL(SUBSTRB(hlo.address_lines_phonetic, 1, 15), cv_null)
       OR    NVL(xcp.fax, cv_null)              <> NVL(SUBSTRB(hlo.address4, 1,15), cv_null))
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 add end by Shigeto.Niki
      FOR UPDATE OF xcp.party_id  NOWAIT
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify end by Yutaka.Kuboshima
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
--    --==============================================================
--    -- �P�D�����ΏۂƂȂ�p�[�e�B�A�h�I���̃��R�[�h���b�N���s���܂��B
--    --==============================================================
--    BEGIN
--      OPEN  parties_data_lock_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
--      CLOSE parties_data_lock_cur;
----
--    --==============================================================
--    -- �Q�D���b�N�Ɏ��s�����ꍇ�A���b�N�G���[
--    --==============================================================
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_app_name_xxcmm    -- �}�X�^
--                       ,iv_name         => cv_msg_00008         -- �G���[  :���b�N�G���[
--                       ,iv_token_name1  => cv_tok_ng_table      -- �g�[�N��:NG_TABLE
--                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- �l      :�p�[�e�B�A�h�I��
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--    END;
--
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
--
    --==============================================================
    -- �R�D�����ΏۂƂȂ�p�[�e�B�A�h�I���̒��o���A
    --     ���ʂ�z��Ɋi�[���܂��B
    --==============================================================
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify start by Yutaka.Kuboshima
--    -- �p�[�e�B�A�h�I���擾�J�[�\���̃I�[�v��
--    OPEN parties_data_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
--    -- �����ΏۂƂȂ�p�[�e�B�A�h�I���̎擾
--    <<output_data_loop>>
--    LOOP
--      FETCH parties_data_cur BULK COLLECT INTO gt_parties_tab;
--      EXIT WHEN parties_data_cur%NOTFOUND;
--    END LOOP output_data_loop;
--    -- �p�[�e�B�A�h�I���擾�J�[�\���̃N���[�Y
--    CLOSE parties_data_cur;
    --==============================================================
    -- �P�D�����ΏۂƂȂ�p�[�e�B�A�h�I���̃��R�[�h���b�N�ƁA
    --     �����Ώۃ��R�[�h�̒��o���ʂ�z��Ɋi�[���܂��B
    --==============================================================
    BEGIN
      -- �p�[�e�B�A�h�I���擾�J�[�\���̃I�[�v��
      OPEN parties_data_cur(gd_proc_date_from, gd_proc_date_to, gv_sal_org_id, gv_mfg_org_id);
      -- �����ΏۂƂȂ�p�[�e�B�A�h�I���̎擾
      <<output_data_loop>>
      LOOP
        FETCH parties_data_cur BULK COLLECT INTO gt_parties_tab;
        EXIT WHEN parties_data_cur%NOTFOUND;
      END LOOP output_data_loop;
      -- �p�[�e�B�A�h�I���擾�J�[�\���̃N���[�Y
      CLOSE parties_data_cur;
    --==============================================================
    -- �Q�D���b�N�Ɏ��s�����ꍇ�A���b�N�G���[
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- �}�X�^
                       ,iv_name         => cv_msg_00008         -- �G���[  :���b�N�G���[
                       ,iv_token_name1  => cv_tok_ng_table      -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- �l      :�p�[�e�B�A�h�I��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2010/02/18 Ver1.3 E_�{�ғ�_01419 modify end by Yutaka.Kuboshima
    -- �������擾
    gn_target_cnt := gt_parties_tab.COUNT;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_parties_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_linkage_item
   * Description      : �A�g���ڃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_linkage_item(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.�p�[�e�B�A�h�I���X�V�f�[�^
    ov_errbuf         OUT VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_linkage_item'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cv_party_name_col_name           CONSTANT VARCHAR2(20) := '�ڋq����';
    cn_party_name_col_size           CONSTANT NUMBER := 60;  -- (�T�C�Y)�ڋq����
    cv_party_short_name_col_name     CONSTANT VARCHAR2(20) := '����';
    cn_party_short_name_col_size     CONSTANT NUMBER := 20;  -- (�T�C�Y)�ڋq����
    cv_party_name_alt_col_name       CONSTANT VARCHAR2(20) := '�J�i��';
    cv_party_name_alt_col_size       CONSTANT NUMBER := 30;  -- (�T�C�Y)�ڋq�J�i��
    cv_postal_code_col_name          CONSTANT VARCHAR2(20) := '�X�֔ԍ�';
    cn_postal_code_col_size          CONSTANT NUMBER := 8;   -- (�T�C�Y)�X�֔ԍ�
    cv_address_line_col_name         CONSTANT VARCHAR2(20) := '�Z��';
    cn_address_line_col_size         CONSTANT NUMBER := 60;  -- (�T�C�Y)�Z��
    cv_phone_col_name                CONSTANT VARCHAR2(20) := '�d�b�ԍ�';
    cn_phone_col_size                CONSTANT NUMBER := 15;  -- (�T�C�Y)�d�b�ԍ�
    cv_fax_col_name                  CONSTANT VARCHAR2(20) := 'FAX�ԍ�';
    cn_fax_col_size                  CONSTANT NUMBER := 15;  -- (�T�C�Y)FAX�ԍ�
    -- *** ���[�J���ϐ� ***
    lt_party_id    xxcmn_parties.party_id%TYPE;           -- �p�[�e�BID
    lt_cust_cd     hz_cust_accounts.account_number%TYPE;  -- �ڋq�R�[�h
    lv_data_value  VARCHAR2(2000);  -- �}���E�X�V�Ώۃf�[�^�̓��e
    ln_data_size   NUMBER;          -- �}���E�X�V�Ώۃf�[�^�̃T�C�Y
    lb_is_checked  BOOLEAN;         -- �T�C�Y�`�F�b�N�t���O�i�`�F�b�N�����TRUE �`�F�b�N�Ȃ���FALSE)
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lt_party_id := it_parties_rec.party_id;
    lt_cust_cd  := it_parties_rec.account_number;
    lb_is_checked := FALSE;
--
    --==============================================================
    -- �P�D�ڋq���̂̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- �ڋq���̂̒l���擾
    lv_data_value := it_parties_rec.party_name;
    -- �ڋq���̂̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- �ڋq���̂̃T�C�Y��60Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_party_name_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_party_name_col_name       -- �l      :�ڋq����
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_party_name_col_size       -- �l      :�ڋq����(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :�ڋq����(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :�ڋq����(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �Q�D���̂̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- ���̂̒l���擾
    lv_data_value := it_parties_rec.party_short_name;
    -- ���̂̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- ���̂̃T�C�Y��20Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_party_short_name_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_party_short_name_col_name -- �l      :����
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_party_short_name_col_size -- �l      :����(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :����(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :����(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �R�D�J�i���̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- �J�i���̒l���擾
    lv_data_value := it_parties_rec.party_name_alt;
    -- �J�i���̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- �J�i���̃T�C�Y��30Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cv_party_name_alt_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_party_name_alt_col_name   -- �l      :�J�i��
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cv_party_name_alt_col_size   -- �l      :�J�i��(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :�J�i��(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :�J�i��(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �S�D�X�֔ԍ��̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- �X�֔ԍ��̒l���擾
    lv_data_value := it_parties_rec.postal_code;
    -- �X�֔ԍ��̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- �X�֔ԍ��̃T�C�Y��8Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_postal_code_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_postal_code_col_name      -- �l      :�X�֔ԍ�
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_postal_code_col_size      -- �l      :�X�֔ԍ�(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :�X�֔ԍ�(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :�X�֔ԍ�(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �T�D�Z���̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- �Z���̒l���擾
    lv_data_value := it_parties_rec.state || it_parties_rec.city
                      || it_parties_rec.address1 || it_parties_rec.address2;
    -- �Z���̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- �Z���̃T�C�Y��60Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_address_line_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_address_line_col_name     -- �l      :�Z��
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_address_line_col_size     -- �l      :�Z��(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :�Z��(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :�Z��(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �U�D�d�b�ԍ��̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- �d�b�ԍ��̒l���擾
    lv_data_value := it_parties_rec.phone;
    -- �d�b�ԍ��̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- �d�b�ԍ��̃T�C�Y��15Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_phone_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_phone_col_name            -- �l      :�d�b�ԍ�
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_phone_col_size            -- �l      :�d�b�ԍ�(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :�d�b�ԍ�(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :�d�b�ԍ�(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
    --==============================================================
    -- �V�DFAX�ԍ��̎擾�f�[�^�T�C�Y���`�F�b�N
    --==============================================================
    -- FAX�ԍ��̒l���擾
    lv_data_value := it_parties_rec.fax;
    -- FAX�ԍ��̃T�C�Y���擾
    ln_data_size  := LENGTHB(lv_data_value);
    -- FAX�ԍ��̃T�C�Y��15Byte�ȏ�̏ꍇ�A�x�����b�Z�[�W�o��
    IF ( ln_data_size > cn_fax_col_size ) THEN
        --(�x�����b�Z�[�W���擾)
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm            -- �}�X�^
                       ,iv_name         => cv_msg_00702                 -- �G���[  :���Y�A�g���ڃT�C�Y�x��
                       ,iv_token_name1  => cv_tok_ng_table              -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name          -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd               -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd                   -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id              -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id                  -- �l      :�p�[�e�BID(�l)
                       ,iv_token_name4  => cv_tok_col_name              -- �g�[�N��:COL_NAME
                       ,iv_token_value4 => cv_fax_col_name              -- �l      :FAX�ԍ�
                       ,iv_token_name5  => cv_tok_col_size              -- �g�[�N��:COL_SIZE
                       ,iv_token_value5 => cn_fax_col_size              -- �l      :FAX�ԍ�(�ő�T�C�Y)
                       ,iv_token_name6  => cv_tok_data_size             -- �g�[�N��:DATA_SIZE
                       ,iv_token_value6 => ln_data_size                 -- �l      :FAX�ԍ�(�Ώۂ̃T�C�Y)
                       ,iv_token_name7  => cv_tok_data_val              -- �g�[�N��:DATA_VAL
                       ,iv_token_value7 => lv_data_value                -- �l      :FAX�ԍ�(�Ώۂ̓��e)
                     );
        --(�x�����b�Z�[�W���o��(�o�́E���O�j)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --(�t���O���Z�b�g�j
        lb_is_checked := TRUE;
    END IF;
--
-- 2010/02/23 Ver1.4 E_�{�ғ�_01419 delete start by Yutaka.Kuboshima
-- �`�F�b�N�G���[���ł�����I�������邽�ߍ폜
--  -- �X�e�[�^�X�̃`�F�b�N
--  IF ( lb_is_checked = TRUE ) THEN
--    RAISE size_over_expt;
--  END IF;
-- 2010/02/23 Ver1.4 E_�{�ғ�_01419 delete end by Yutaka.Kuboshima
--
  EXCEPTION
    -- *** ���Y�A�g���ڃT�C�Y�I�[�o��O ***
    WHEN size_over_expt THEN
      ov_retcode := cv_status_warn;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_linkage_item;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcmn_parties
   * Description      : �p�[�e�B�A�h�I���X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_xxcmn_parties(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.�p�[�e�B�A�h�I���X�V�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcmn_parties'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lt_party_id     xxcmn_parties.party_id%TYPE;           -- �p�[�e�BID
    lt_cust_cd      hz_cust_accounts.account_number%TYPE;  -- �ڋq�R�[�h
    lv_address_line VARCHAR2(60);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �P�D�p�[�e�B�A�h�I�����X�V
    --==============================================================
    -- �����ݒ�
    lt_party_id     := it_parties_rec.party_id;
    lt_cust_cd      := it_parties_rec.account_number;
    lv_address_line := SUBSTRB(it_parties_rec.state || it_parties_rec.city
                        || it_parties_rec.address1 || it_parties_rec.address2,1,60);
    -- �X�V
    BEGIN
      UPDATE xxcmn_parties xpts   -- (table)�p�[�e�B�A�h�I��
      SET    xpts.party_name        = SUBSTRB(it_parties_rec.party_name, 1, 60)
            ,xpts.party_short_name  = SUBSTRB(it_parties_rec.party_short_name, 1, 20)
            ,xpts.party_name_alt    = SUBSTRB(it_parties_rec.party_name_alt, 1, 30)
            ,xpts.zip               = SUBSTRB(it_parties_rec.postal_code, 1, 8)
            ,xpts.address_line1     = SUBSTRB(lv_address_line,  1, 30)
            ,xpts.address_line2     = SUBSTRB(lv_address_line, 31, 30)
            ,xpts.phone             = SUBSTRB(it_parties_rec.phone, 1, 15)
            ,xpts.fax               = SUBSTRB(it_parties_rec.fax, 1,15)
            --WHO�J����
            ,last_updated_by        = cn_last_updated_by
            ,last_update_date       = cd_last_update_date
            ,last_update_login      = cn_last_update_login
            ,request_id             = cn_request_id
            ,program_application_id = cn_program_application_id
            ,program_id             = cn_program_id
            ,program_update_date    = cd_program_update_date
      WHERE  xpts.party_id          = lt_party_id
      ;
--
    --==============================================================
    -- �Q�D�X�V���s���A���L�G���[���b�Z�[�W�\��
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- �}�X�^
                       ,iv_name         => cv_msg_00700         -- �G���[  :�p�[�e�B�A�h�I���X�V�G���[
                       ,iv_token_name1  => cv_tok_ng_table      -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd       -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd           -- �l      :�ڋq�R�[�h(�l)
                       ,iv_token_name3  => cv_tok_party_id      -- �g�[�N��:PARTY_ID
                       ,iv_token_value3 => lt_party_id          -- �l      :�p�[�e�BID(�l)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_xxcmn_parties;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcmn_parties
   * Description      : �p�[�e�B�A�h�I���o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_xxcmn_parties(
    it_parties_rec  IN  xxcmn_parties_rtype,  -- 1.�p�[�e�B�A�h�I���X�V�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcmn_parties'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lt_party_id     xxcmn_parties.party_id%TYPE;           -- �p�[�e�BID
    lt_cust_cd      hz_cust_accounts.account_number%TYPE;  -- �ڋq�R�[�h
    lv_address_line VARCHAR2(60);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �P�D�p�[�e�B�A�h�I����o�^
    --==============================================================
    -- �����ݒ�
    lt_party_id     := it_parties_rec.party_id;
    lt_cust_cd      := it_parties_rec.account_number;
    lv_address_line := SUBSTRB(it_parties_rec.state || it_parties_rec.city
                        || it_parties_rec.address1 || it_parties_rec.address2,1,60);
    -- �o�^
    BEGIN
      --XXXX�f�[�^�}������
      INSERT INTO xxcmn_parties (
         party_id               -- (��)�p�[�e�B�[ID
        ,start_date_active      -- (��)�K�p�J�n��
        ,end_date_active        -- (��)�K�p�I����
        ,party_name             -- (��)������
        ,party_short_name       -- (��)����
        ,party_name_alt         -- (��)�J�i��
        ,zip                    -- (��)�X�֔ԍ�
        ,address_line1          -- (��)�Z���P
        ,address_line2          -- (��)�Z���Q
        ,phone                  -- (��)�d�b�ԍ�
        ,fax                    -- (��)FAX�ԍ�
        ,reserve_order          -- (��)������
        ,drink_transfer_std     -- (��)�h�����N�^���U�֊
        ,leaf_transfer_std      -- (��)���[�t�^���U�֊
        ,transfer_group         -- (��)�U�փO���[�v
        ,distribution_block     -- (��)�����u���b�N
        ,base_major_division    -- (��)���_�啪��
        ,eos_detination         -- (��)EOS����
        ,created_by             -- (��)�쐬��
        ,creation_date          -- (��)�쐬��
        ,last_updated_by        -- (��)�ŏI�X�V��
        ,last_update_date       -- (��)�ŏI�X�V��
        ,last_update_login      -- (��)�ŏI�X�V۸޲�
        ,request_id             -- (��)�v��ID
        ,program_application_id -- (��)�ݶ��ĥ��۸��ѥ���ع����ID
        ,program_id             -- (��)�ݶ��ĥ��۸���ID
        ,program_update_date    -- (��)��۸��эX�V��
      )VALUES(
         lt_party_id                                       -- (�l)�p�[�e�B�[ID
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 modify start by Yutaka.Kuboshima
--        ,gd_process_date + 1                               -- (�l)�K�p�J�n��
        ,gd_process_date                                  -- (�l)�K�p�J�n��
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 modify end by Yutaka.Kuboshima
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify start by Shigeto.Niki    
--        ,TO_DATE('99991231', 'YYYYMMDD')                   -- (�l)�K�p�I����
        ,TO_DATE(cv_max_date , cv_date_fmt)                -- (�l)�K�p�I����
-- 2010/05/28 Ver1.5 ��Q�FE_�{�ғ�_02876 modify end by Shigeto.Niki    
        ,SUBSTRB(it_parties_rec.party_name, 1, 60)         -- (�l)������
        ,SUBSTRB(it_parties_rec.party_short_name, 1, 20)   -- (�l)����
        ,SUBSTRB(it_parties_rec.party_name_alt, 1, 30)     -- (�l)�J�i��
        ,SUBSTRB(it_parties_rec.postal_code, 1, 8)         -- (�l)�X�֔ԍ�
        ,SUBSTRB(lv_address_line,  1, 30)                  -- (�l)�Z���P
        ,SUBSTRB(lv_address_line, 31, 30)                  -- (�l)�Z���Q
        ,SUBSTRB(it_parties_rec.phone, 1, 15)              -- (�l)�d�b�ԍ�
        ,SUBSTRB(it_parties_rec.fax, 1, 15)                -- (�l)FAX�ԍ�
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 modify start by Yutaka.Kuboshima
--        ,gv_pro_init01                                     -- (�l)������
--        ,gv_pro_init06                                     -- (�l)�h�����N�^���U�֊
--        ,gv_pro_init07                                     -- (�l)���[�t�^���U�֊
--        ,gv_pro_init03                                     -- (�l)�U�փO���[�v
--        ,gv_pro_init04                                     -- (�l)�����u���b�N
         -- �����l��NULL�ɕύX
        ,NULL                                              -- (�l)������
        ,NULL                                              -- (�l)�h�����N�^���U�֊
        ,NULL                                              -- (�l)���[�t�^���U�֊
        ,NULL                                              -- (�l)�U�փO���[�v
        ,NULL                                              -- (�l)�����u���b�N
-- 2010/02/15 Ver1.2 E_�{�ғ�_01419 modify end by Yutaka.Kuboshima
        ,gv_pro_init05                                     -- (�l)���_�啪��
        ,NULL                                              -- (�l)EOS����
        ,cn_created_by                                     -- (�l)�쐬��
        ,cd_creation_date                                  -- (�l)�쐬��
        ,cn_last_updated_by                                -- (�l)�ŏI�X�V��
        ,cd_last_update_date                               -- (�l)�ŏI�X�V��
        ,cn_last_update_login                              -- (�l)�ŏI�X�V۸޲�
        ,cn_request_id                                     -- (�l)�v��ID
        ,cn_program_application_id                         -- (�l)�ݶ��ĥ��۸��ѥ���ع����ID
        ,cn_program_id                                     -- (�l)�ݶ��ĥ��۸���ID
        ,cd_program_update_date                            -- (�l)��۸��эX�V��
      );
--
    --==============================================================
    -- �Q�D�o�^���s���A���L�G���[���b�Z�[�W�\��
    --==============================================================
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- �}�X�^
                       ,iv_name         => cv_msg_00701         -- �G���[  :�p�[�e�B�A�h�I���o�^�G���[
                       ,iv_token_name1  => cv_tok_ng_table      -- �g�[�N��:NG_TABLE
                       ,iv_token_value1 => cv_tvl_upd_tbl_name  -- �l      :�p�[�e�B�A�h�I��
                       ,iv_token_name2  => cv_tok_cust_cd       -- �g�[�N��:CUST_CD
                       ,iv_token_value2 => lt_cust_cd           -- �l      :�ڋq�R�[�h(�l)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_xxcmn_parties;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
   -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_idx     NUMBER;          -- ���l
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_yes       CONSTANT VARCHAR2(1) := 'Y';
    cv_flag_no        CONSTANT VARCHAR2(1) := 'N';
--
    -- *** ���[�J���ϐ� ***
    lv_tvl_para       VARCHAR2(100);  -- �g�[�N���Ɋi�[����l
    lv_out_msg        VARCHAR2(5000); -- �o�͗p
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
--
    -- ===============================================
    -- A-1.��������
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���̓p�����[�^(������(From))�̏o�̓��b�Z�[�W���擾
    -- �E������(From)��NULL     �� �������iFrom�j �F [] : �����擾[YYYY/MM/DD]
    -- �E������(From)��NULL�ȊO �� �������iFrom�j �F [YYYY/MM/DD]
    IF ( gv_in_proc_date_from IS NULL ) THEN
      lv_tvl_para := cv_tvl_auto_st || TO_CHAR(gd_proc_date_from, cv_date_fmt) || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    ELSE
      lv_tvl_para := cv_tvl_para_st || gv_in_proc_date_from || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_from
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- ���̓p�����[�^(������(From))���R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ���̓p�����[�^(������(To))�̏o�̓��b�Z�[�W���擾
    -- �E������(To)��NULL     �� �������iTo�j �F [] : �����擾[YYYY/MM/DD]
    -- �E������(To)��NULL�ȊO �� �������iTo�j �F [YYYY/MM/DD]
    IF ( gv_in_proc_date_to IS NULL ) THEN
      lv_tvl_para := cv_tvl_auto_st || TO_CHAR(gd_proc_date_to, cv_date_fmt) || cv_tvl_auto_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    ELSE
      lv_tvl_para := cv_tvl_para_st || gv_in_proc_date_to || cv_tvl_para_en;
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00038
                      ,iv_token_name1  => cv_tok_param
                      ,iv_token_value1 => cv_tvl_update_to
                      ,iv_token_name2  => cv_tok_value
                      ,iv_token_value2 => lv_tvl_para
                     );
    END IF;
    -- ���̓p�����[�^(������(To))���R���J�����g��o�͂ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ���������̎��s���ʃ`�F�b�N
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2�D�����Ώۃf�[�^���o
    -- ===============================================
    get_parties_data(
       ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- �����`�F�b�N
    IF ( gn_target_cnt = 0 ) THEN
      --(���b�Z�[�W�o��)
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_xxcmm
                      ,iv_name         => cv_msg_00001
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_out_msg
      );
      --(��O���X���[�j
      RAISE no_output_data_expt;
    END IF;
--
    <<ins_parties_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      -- ===============================================
      -- A-3�D�A�g���ڃ`�F�b�N
      -- ===============================================
      chk_linkage_item(
         it_parties_rec  => gt_parties_tab(ln_idx)  -- ���[�vA�̃J�[�\��(A-2�Ŏ擾�����f�[�^��1���R�[�h)
        ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �������ʃ`�F�b�N(�G���[)
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      -- �������ʃ`�F�b�N(�x��)
      ELSIF (lv_retcode = cv_status_warn) THEN
        --(���^�[���E�R�[�h�Ɍx�����Z�b�g�j
        ov_retcode := cv_status_warn;
      END IF;
--
      -- ===============================================
      -- A-4�D�p�[�e�B�A�h�I���X�V
      -- ===============================================
      IF ( gt_parties_tab(ln_idx).xxcmn_perties_active_flag = cv_flag_yes ) THEN
        upd_xxcmn_parties(
           it_parties_rec  => gt_parties_tab(ln_idx)  -- ���[�vA�̃J�[�\��(A-2�Ŏ擾�����f�[�^��1���R�[�h)
          ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �������ʃ`�F�b�N(�G���[)
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      -- ===============================================
      -- A-5. �p�[�e�B�A�h�I���o�^
      -- ===============================================
      ELSIF ( gt_parties_tab(ln_idx).xxcmn_perties_active_flag = cv_flag_no ) THEN
        ins_xxcmn_parties(
           it_parties_rec  => gt_parties_tab(ln_idx)  -- ���[�vA�̃J�[�\��(A-2�Ŏ擾�����f�[�^��1���R�[�h)
          ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �������ʃ`�F�b�N
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END IF;
      -- �����������X�V
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP ins_parties_loop;
--
  EXCEPTION
    -- *** �Ώۃf�[�^������O�n���h�� ***
    WHEN no_output_data_expt THEN
      ov_retcode := cv_status_normal;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_proc_date_from     IN     VARCHAR2,        --   1.������(FROM)
    iv_proc_date_to       IN     VARCHAR2)        --   2.������(TO)
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code     VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    -- ===============================================
    -- ���̓p�����[�^�̎擾
    -- ===============================================
    gv_in_proc_date_from := iv_proc_date_from;
    gv_in_proc_date_to   := iv_proc_date_to;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf           => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- A-6. �I������
    -- ===============================================
    -- ���^�[���E�R�[�h���ُ�I���̏ꍇ�̃��b�Z�[�W�o�� �A �����̎Z�o
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�����̓o�^
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_normal OR retcode = cv_status_warn ) THEN
      COMMIT;
    ELSIF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
END XXCMM007A01C;
/
