create or replace
PACKAGE BODY XXCFF_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON2_PKG(body)
 * Description      : FA���[�X���ʏ���
 * MD.050           : �Ȃ�
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_match_chk      �x���ƍ��σ`�F�b�N
 *  get_lease_key          ���[�X�L�[�̎擾
 *  get_object_info        �����R�[�h���[�X�敪�A���[�X��ʃ`�F�b�N
 *  chk_object_term        �����R�[�h���`�F�b�N
 *  <program name>         <����> (�����ԍ�)
 *  �쐬���ɋL�q���Ă�������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0    SCS���          �V�K�쐬
 *  2008/12/05    1.1    SCS���c          �ǉ��F�����R�[�h���`�F�b�N
 *  2009/02/18    1.2    SCS�E��          �x���ƍ��σ`�F�b�N�̌���������ύX
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
  object_comp_type          EXCEPTION;     -- �����̑�����r��O(���[�X�敪)
  object_comp_class         EXCEPTION;     -- �����̑�����r��O(���[�X���)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF_COMMON2_PKG'; -- �p�b�P�[�W��
  cv_appl_name     CONSTANT VARCHAR2(100) := 'XXCFF'; -- �A�v���P�[�V������
--
  --�G���[���b�Z�[�W��
  cv_msg_name1     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00157'; -- �p�����[�^�K�{�G���[
  cv_msg_name6     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00161'; -- ���`�F�b�N�G���[
  cv_msg_name7     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00162'; -- ���\���`�F�b�N�G���[
  cv_msg_name2     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00186'; -- ��v���Ԏ擾�G���[
--
  --�g�[�N����
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'INPUT';
--
  --�g�[�N���l
  cv_tkn_val2      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50016'; -- ��������ID
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
   * Procedure Name   : payment_match_chk
   * Description      : �x���ƍ��σ`�F�b�N
   ***********************************************************************************/
 PROCEDURE payment_match_chk(
    in_line_id    IN  NUMBER,          --   1.�_�񖾍ד���ID
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W         --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h           --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
)  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_match_chk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_check_count   NUMBER(1);
    ld_process_date  DATE;
    lv_period_name   gl_periods_v.period_name%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    init_rtype_rec                 XXCFF_COMMON1_PKG.init_rtype;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�Ɩ����t�擾 2009/2/9 �J�����݂̂̈ꎞ�Ή� 
    XXCFF_COMMON1_PKG.init(or_init_rec => init_rtype_rec
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg);
--    ld_process_date           := xxccp_common_pkg2.get_process_date;
    ld_process_date           := init_rtype_rec.process_date;
    --�Ɩ����t�擾 2009/2/9 �J�����݂̂̈ꎞ�Ή� �����܂�
    BEGIN
      --�Ɩ����t�ɑΉ������v���Ԗ��擾
      SELECT
             period_name
      INTO
             lv_period_name
      FROM
             gl_periods_v
      WHERE
             period_set_name        = 'SALES_CALENDAR'
        AND  adjustment_period_flag = 'N'
        AND  start_date            <= ld_process_date
        AND  end_date              >= ld_process_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                      --*** ��v���Ԃ��擾�ł��Ȃ���Έُ� ***
        -- *** �C�ӂŗ�O�������L�q���� ****
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name2);
        RAISE global_api_others_expt;
    END;
    --�ƍ��σf�[�^�̑��݂��m�F
    SELECT
           COUNT(contract_line_id)
     INTO
           ln_check_count
     FROM
           xxcff_pay_planning
    WHERE
           contract_line_id   = in_line_id
     AND   period_name       >= lv_period_name
--   AND NOT(payment_match_flag = '0'       --�x���ƍ����ƍ�
--       AND accounting_if_flag = '1')      --�����M
     AND  ((payment_match_flag = '1')       --�x���ƍ���
     OR    (payment_match_flag = '0'        --�x���ƍ����ƍ�
       AND  accounting_if_flag = '3'))      --�ƍ��ł���
     AND   ROWNUM             = 1;
    --==============================================================
    --�ƍ��ς̃��R�[�h��1���ȏ㑶�݂��Ă���̂Ń`�F�b�N�G���[�Ƃ���
    --==============================================================
--��DEBUG
    IF (ln_check_count <> 0) THEN
      --�G���[���b�Z�[�W���擾
      ov_retcode := cv_status_warn;                                            --# �C�� #
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                           --*** �ƍ��ς̎x���v�悪�Ȃ��ꍇ���� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := NULL;                                                  --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END payment_match_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_key
   * Description      : ���[�X�L�[���擾
   ***********************************************************************************/
  PROCEDURE get_lease_key(
    iv_objectcode IN  VARCHAR2,        --   1.�����R�[�h(�K�{)
    on_object_id  OUT NUMBER,          --   2.���������h�c
    on_contact_id OUT NUMBER,          --   3.�_������h�c
    on_line_id    OUT NUMBER,          --   4.�_�񖾍ד����h�c
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
)  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_key'; -- �v���O������
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
    ln_object_id      xxcff_object_headers.object_header_id%TYPE    := NULL;  --   ���������h�c
    ln_line_id        xxcff_contract_lines.contract_line_id%TYPE    := NULL;  --   �_�񖾍ד����h�c
    ln_cont_id        xxcff_contract_lines.contract_header_id%TYPE  := NULL;  --   �_������h�c
    ln_re_lease_times xxcff_object_headers.re_lease_times%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --��������ID�擾
    SELECT xoh.object_header_id
          ,xoh.re_lease_times
    INTO
           ln_object_id         --   ���������h�c
          ,ln_re_lease_times    --   �ă��[�X��
    FROM
           xxcff_object_headers xoh
    WHERE
           object_code        = iv_objectcode;
    --�_�����ID,�_�񖾍ד���ID�擾
    SELECT
           xcl.contract_header_id
          ,xcl.contract_line_id
    INTO
           ln_cont_id           --   �_������h�c
          ,ln_line_id           --   �_�񖾍ד����h�c
    FROM
           xxcff_contract_headers xch
          ,xxcff_contract_lines xcl
    WHERE
           xcl.object_header_id    = ln_object_id
      AND  xch.contract_header_id  = xcl.contract_header_id
      AND  xch.re_lease_times      = ln_re_lease_times;
    -- �擾���e��OUT�p�����[�^�ɐݒ�
    on_object_id  := ln_object_id; --   2.���������h�c
    on_contact_id := ln_cont_id;   --   3.�_������h�c
    on_line_id    := ln_line_id;   --   4.�_�񖾍ד����h�c
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                           --*** ��񂪎擾�ł��Ȃ��Ă�����I��
      -- *** �C�ӂŗ�O�������L�q���� ****
      on_object_id  := ln_object_id; --   2.���������h�c
      on_contact_id := ln_cont_id;   --   3.�_������h�c
      on_line_id    := ln_line_id;   --   4.�_�񖾍ד����h�c
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
  END get_lease_key;
--
--
  /**********************************************************************************
   * Procedure Name   : get_object_info
   * Description      : �����R�[�h���[�X�敪�A���[�X��ʃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE get_object_info(
    in_object_id   IN  NUMBER,          --   1.�����R�[�h(�K�{)
    iv_lease_type  IN  VARCHAR2,        --   2.���[�X�敪(�K�{)
    iv_lease_class IN  VARCHAR2,        --   3.���[�X���(�K�{)
    in_re_lease_times IN  NUMBER,       --   4.�ă��[�X�񐔁i�K�{�j
    ov_errbuf      OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
)  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_info'; -- �v���O������
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
    lv_err_item       VARCHAR2(1000);  --   �G���[����
    ln_rec_cnt        NUMBER(10);  --   �G���[����
    lv_lease_type     xxcff_object_headers.lease_type%type;     --   ���[�X�敪
    lv_lease_class    xxcff_object_headers.lease_class%type;    --   ���[�X���
    ln_re_lease_times xxcff_object_headers.re_lease_times%type; --   �ă��[�X��
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�f�[�^�擾����
    --==============================================================
    --��������ID�ɑΉ����郌�R�[�h���J�E���g����
    --==============================================================
    SELECT
           COUNT(object_header_id)
    INTO
           ln_rec_cnt
    FROM
           xxcff_object_headers xoh
    WHERE
           xoh.object_header_id   = in_object_id
    ;
    --==============================================================
    --��������ID�ɑΉ����郌�R�[�h�����݂��邩�m�F
    --==============================================================
    IF (ln_rec_cnt = 0) THEN
      ov_retcode := cv_status_error;
      return;
    END IF;
    --==============================================================
    --��������ID�ƍă��[�X�񐔂��w�肵�ă��R�[�h������
    --==============================================================
    SELECT
           XOH.lease_type
          ,XOH.lease_class
          ,XOH.re_lease_times
    INTO
           lv_lease_type         --   ���[�X�敪
          ,lv_lease_class        --   ���[�X���
          ,ln_re_lease_times
    FROM
           XXCFF_OBJECT_HEADERS XOH
    WHERE
           XOH.OBJECT_HEADER_ID   = in_object_id
      AND  XOH.re_lease_times     = in_re_lease_times
    ;
    --==============================================================
    --���[�X�敪���r�m�F����
    --==============================================================
    IF (lv_lease_type <> iv_lease_type) THEN
        RAISE  object_comp_type;
    END IF;
    --==============================================================
    --���[�X��ʂ��r�m�F����
    --==============================================================
    IF (lv_lease_class <> iv_lease_class) THEN
        RAISE  object_comp_class;
    END IF;
--
  EXCEPTION
--
    WHEN NO_DATA_FOUND THEN                      --���[�X�񐔂��s��v
        ov_retcode := cv_status_warn;
    WHEN object_comp_type THEN                   --*** ���[�X�敪���s��v�̏ꍇ�̓G���[ ***
        ov_retcode := cv_status_warn;
    WHEN object_comp_class THEN                  --*** ���[�X��ʂ��s��v�̏ꍇ�̓G���[ ***
        ov_retcode := cv_status_warn;
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
  END get_object_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_object_term
   * Description      : �����R�[�h���`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_object_term(
    in_object_header_id  IN  NUMBER,                --   1.��������ID(�K�{)
    iv_term_appl_chk_flg IN  VARCHAR2 DEFAULT 'N',  --   2.���\���`�F�b�N�t���O(�f�t�H���g�l�F'N')
    ov_errbuf            OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_term'; -- �v���O������
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
    ln_check_count   PLS_INTEGER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    term_check_expt       EXCEPTION;  --�����R�[�h���`�F�b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�K�{���ڃ`�F�b�N
    IF ( in_object_header_id IS NULL ) THEN
      --�K�{�p�����[�^�u ��������ID �v�������͂ł��B
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name1
                                            ,cv_tkn_name1,cv_tkn_val2);
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --���ς�/�����`�F�b�N
    IF ( iv_term_appl_chk_flg = 'N' ) THEN
      --�f�[�^�擾����
      SELECT
             COUNT( ROWNUM )
      INTO
             ln_check_count
      FROM
             xxcff_object_headers  xoh  -- ���[�X����
           , xxcff_object_status_v xos  -- �����X�e�[�^�X�r���[
      WHERE
             xoh.object_header_id   = in_object_header_id
        AND  xos.object_status_code = xoh.object_status
        AND  xos.no_adjusts_flag    = 'Y';      --�C���s��(���ς�/����)
--
      --===================================================================================
      --���ς݁A�������͖����̏�Ԃ̃��R�[�h��1���ȏ㑶�݂��Ă���̂Ń`�F�b�N�G���[�Ƃ���
      --===================================================================================
      IF ( ln_check_count <> 0 ) THEN
        --�G���[���b�Z�[�W���擾
        --�Y���̕����́A���ς݁A�������͖����̏�Ԃł��B
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name6);
        lv_errbuf  := lv_errmsg;
        RAISE term_check_expt;
      END IF;
--
    --���ς�/����/���\�����`�F�b�N
    ELSIF ( iv_term_appl_chk_flg = 'Y' ) THEN
      --�f�[�^�擾����
      SELECT
             COUNT( ROWNUM )
      INTO
             ln_check_count
      FROM
             xxcff_object_headers  xoh  -- ���[�X����
           , xxcff_object_status_v xos  -- �����X�e�[�^�X�r���[
      WHERE
             xoh.object_header_id   = in_object_header_id
        AND  xos.object_status_code = xoh.object_status
        AND  xos.bond_accept_flag   = 'Y';      --�؏���̉\(���ς�/����/���\����)
--
      --=========================================================================
      --���\���ȍ~�̏�Ԃ̃��R�[�h��1���ȏ㑶�݂��Ă���̂Ń`�F�b�N�G���[�Ƃ���
      --=========================================================================
      IF ( ln_check_count <> 0 ) THEN
        --�G���[���b�Z�[�W���擾
        --�Y���̕����́A���\���ȍ~�̏�Ԃł��B
        lv_errmsg  := xxccp_common_pkg.get_msg(cv_appl_name,cv_msg_name7);
        lv_errbuf  := lv_errmsg;
        RAISE term_check_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                    --*** ���������ς݁A�����A���\�����łȂ��ꍇ���� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := NULL;                                                  --# �C�� #
    -- *** �����R�[�h���`�F�b�N�G���[�n���h�� ***
    WHEN term_check_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;  --�x��(�Ɩ��G���[)
--
--###############################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--###################################  �Œ蕔 END   #########################################
--
  END chk_object_term;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFF_COMMON2_PKG;
/