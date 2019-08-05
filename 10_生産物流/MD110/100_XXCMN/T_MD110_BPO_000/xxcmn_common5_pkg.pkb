CREATE OR REPLACE PACKAGE BODY apps.xxcmn_common5_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name           : xxcmn_common5_pkg(body)
 * Description            : ���ʊ֐�5
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�5.xls
 * Version                : 1.2
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_use_by_date       F    DATE  �ܖ������擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/02/22    1.0   H.Sasaki        �V�K�쐬(E_�{�ғ�_14859)
 *  2018/06/18    1.1   H.Sasaki        �s��Ή�(E_�{�ғ�_15154)
 *  2019/07/25    1.2   E.Yazaki        �s��Ή�(E_�{�ғ�_15550)
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common5_pkg'; -- �p�b�P�[�W��
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
   * Function Name    : get_use_by_date
   * Description      : �ܖ������擾�֐�
   ***********************************************************************************/
  FUNCTION  get_use_by_date(
      id_producted_date     IN DATE       --  1.������
    , iv_expiration_type    IN VARCHAR2   --  2.�\���敪
    , in_expiration_day     IN NUMBER     --  3.�ܖ�����
    , in_expiration_month   IN NUMBER     --  4.�ܖ�����(��)
  ) RETURN DATE
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_use_by_date'; -- �v���O������
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
    cv_type_10        CONSTANT VARCHAR2(2)  :=  '10';           --  �\���敪�F�N���\��
    cv_type_20        CONSTANT VARCHAR2(2)  :=  '20';           --  �\���敪�F��E���E���{�\��
    cv_type_30        CONSTANT VARCHAR2(2)  :=  '30';           --  �\���敪�F����
    cv_type_40        CONSTANT VARCHAR2(2)  :=  '40';           --  �\���敪�F���� -1
    cv_date_middle    CONSTANT VARCHAR2(2)  :=  '11';           --  �{�敪�F���{
    cv_date_late      CONSTANT VARCHAR2(2)  :=  '21';           --  �{�敪�F���{
    cv_format_dd      CONSTANT VARCHAR2(2)  :=  'DD';           --  ���t�t�H�[�}�b�g�F��
    cv_format_mm      CONSTANT VARCHAR2(2)  :=  'MM';           --  ���t�t�H�[�}�b�g�F��
    cv_format_ym      CONSTANT VARCHAR2(7)  :=  'YYYY/MM';      --  ���t�t�H�[�}�b�g�F�N��
    cv_format_ymd     CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD';   --  ���t�t�H�[�}�b�g�F�N����
    cv_date_10        CONSTANT VARCHAR2(2)  :=  '10';           --  �ܖ������Œ���t�F10��
    cv_date_20        CONSTANT VARCHAR2(2)  :=  '20';           --  �ܖ������Œ���t�F20��
    cv_date_separate  CONSTANT VARCHAR2(1)  :=  '/';            --  ���t�p��؂蕶��
--
    -- *** ���[�J���ϐ� ***
    ld_use_by_date      DATE;       --  (�߂�l)�ܖ�����
--  V1.2 2019/07/25 Modified START
    lv_use_by_date      VARCHAR2(10); --  �ܖ�����(���������A�u�ܖ�����(��)�v�����㓯���ҏW�p)
--  V1.2 2019/07/25 Modified END
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  V1.2 2019/07/25 Modified START
    -- �ϐ�������
    lv_use_by_date := NULL;
--  V1.2 2019/07/25 Modified END
--
    IF ( in_expiration_month IS NULL OR iv_expiration_type IS NULL ) THEN
      --  �\���敪�A�ܖ�����(���j��NULL
      --  ���������A�u�ܖ����ԁv������ܖ������Ƃ���
      ld_use_by_date  :=  TRUNC( id_producted_date + in_expiration_day );
      RETURN  ld_use_by_date;
    END IF;
--
    IF ( iv_expiration_type = cv_type_10 ) THEN
      --  �\���敪�F�N���\��
--  V1.1 2018/06/18 Modified START
--      --  ���������A�u�ܖ�����(��)�v������̌��������ܖ������Ƃ���
--      ld_use_by_date  :=  TRUNC( LAST_DAY( ADD_MONTHS( id_producted_date, in_expiration_month ) ) );
      --  ���������܂߁A����������u�ܖ�����(��)�v������̌��������ܖ������Ƃ���
      ld_use_by_date  :=  TRUNC( LAST_DAY( ADD_MONTHS( id_producted_date, in_expiration_month - 1 ) ) );
--  V1.1 2018/06/18 Modified END
    ELSIF ( iv_expiration_type = cv_type_20 ) THEN
      -- �\���敪�F��E���E���{�\��
      IF( TO_CHAR( id_producted_date, cv_format_dd ) >= cv_date_late ) THEN
        --  ��������21���`����
        --  ���������A�u�ܖ�����(��)�v�������20�����ܖ������Ƃ���
        ld_use_by_date  :=  TRUNC( TO_DATE( TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_ym ) || cv_date_separate || cv_date_20, cv_format_ymd ) );
      ELSIF ( TO_CHAR( id_producted_date, cv_format_dd ) >= cv_date_middle ) THEN
        --  ��������11���`20��
        --  ���������A�u�ܖ�����(��)�v�������10�����ܖ������Ƃ���
        ld_use_by_date  :=  TRUNC( TO_DATE( TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_ym ) || cv_date_separate || cv_date_10, cv_format_ymd ) );
      ELSE
        --  ��������1���`10��
        --  ���������A�u�ܖ�����(��)�v������̑O�����������ܖ������Ƃ���
        ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ), cv_format_mm ) -1;
      END IF;
    ELSIF ( iv_expiration_type = cv_type_30 ) THEN
      --  �\���敪�F����
      --  ���������A�u�ܖ�����(��)�v������̓������ܖ������Ƃ���
      --  �������A���������݂��Ȃ��ꍇ���������擾
--  V1.2 2019/07/25 Modified START
--      --  �������̏ꍇ�̓����Ƃ́A���t�ɂ�炸���������w��(4/30�Ɠ����Ȃ̂�5/30�ł͂Ȃ�5/31(4���������̓�����5��������))
--      ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ) );
      lv_use_by_date  :=  TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), 'YYYY/MM' ) || TO_CHAR( id_producted_date, '/DD' );
      BEGIN
        ld_use_by_date  :=  TO_DATE( lv_use_by_date, 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          --  ���t�^�ϊ��Ɏ��s�����ꍇ�i���݂��Ȃ����t�̏ꍇ�j�A���������u�ܖ�����(��)�v������̌��������ܖ������Ƃ���
          ld_use_by_date  :=  ADD_MONTHS( id_producted_date, in_expiration_month );
      END;
--  V1.2 2019/07/25 Modified END
      --
    ELSIF ( iv_expiration_type = cv_type_40 ) THEN
      --  �\���敪�F���� -1
      --  ���������A�u�ܖ�����(��)�v������̓����̑O�����ܖ������Ƃ���
      --  �������A���������݂��Ȃ��ꍇ���������擾
--  V1.2 2019/07/25 Modified START
--      --  �������̏ꍇ�̓����Ƃ́A���t�ɂ�炸���������w��(4/30�Ɠ����Ȃ̂�5/30�ł͂Ȃ�5/31(4���������̓�����5��������))
--      ld_use_by_date  :=  TRUNC( ADD_MONTHS( id_producted_date, in_expiration_month ) ) - 1;
      lv_use_by_date  :=  TO_CHAR( ADD_MONTHS( id_producted_date, in_expiration_month ), 'YYYY/MM' ) || TO_CHAR( id_producted_date, '/DD' );
      BEGIN
        ld_use_by_date  :=  TO_DATE( lv_use_by_date, 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          --  ���t�^�ϊ��Ɏ��s�����ꍇ�i���݂��Ȃ����t�̏ꍇ�j�A���������u�ܖ�����(��)�v������̌��������ܖ������Ƃ���
          ld_use_by_date  :=  ADD_MONTHS( id_producted_date, in_expiration_month );
      END;
      --  -1��
      ld_use_by_date  :=  ld_use_by_date - 1;
--  V1.2 2019/07/25 Modified END
    ELSE
      --  ��L�ȊO
      --  ���������A�u�ܖ����ԁv������ܖ������Ƃ���
      ld_use_by_date  :=  TRUNC( id_producted_date + in_expiration_day );
    END IF;
--
    RETURN  ld_use_by_date;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN  NULL;
--
  END get_use_by_date;
--
END xxcmn_common5_pkg;
/
