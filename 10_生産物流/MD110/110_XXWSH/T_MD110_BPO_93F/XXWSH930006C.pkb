CREATE OR REPLACE PACKAGE BODY xxwsh930006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930006C(body)
 * Description      : �C���^�t�F�[�X�f�[�^�폜����
 * MD.050           : ���Y��������                  T_MD050_BPO_935
 * MD.070           : �C���^�t�F�[�X�f�[�^�폜����  T_MD070_BPO_93F
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              ��������                     (A-1)
 *  get_del_data           �p�[�W�Ώے��o����           (A-2)
 *  del_proc               �p�[�W����                   (A-3)
 *  term_proc              �I������                     (A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/22    1.0   Oracle �R�� ��_ ����쐬
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxwsh930006c';  -- �p�b�P�[�W��
  gv_app_name       CONSTANT VARCHAR2(5)   := 'XXWSH';         -- �A�v���P�[�V�����Z�k��
  gv_com_name       CONSTANT VARCHAR2(5)   := 'XXCMN';         -- �A�v���P�[�V�����Z�k��
--
  gv_lookup_type    CONSTANT VARCHAR2(20) := 'XXCMN_D17';
--
  gv_tkn_table      CONSTANT VARCHAR2(20) := 'TABLE';
  gv_tkn_item       CONSTANT VARCHAR2(20) := 'ITEM';
  gv_tkn_key        CONSTANT VARCHAR2(20) := 'KEY';
  gv_tkn_input      CONSTANT VARCHAR2(20) := 'INPUT';
--
  gv_tkn_number_93f_01        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10089'; -- �K�{�G���[
  gv_tkn_number_93f_02        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10003'; -- �e�[�u���擾�G���[
  gv_tkn_number_93f_03        CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019'; -- ���b�N�G���[
--
  gv_tkn_name_location_code   CONSTANT VARCHAR2(50) := '�񍐕���';
  gv_tkn_name_eos_data_type   CONSTANT VARCHAR2(50) := 'EOS�f�[�^���';
  gv_tkn_name_order_ref       CONSTANT VARCHAR2(50) := '�˗�No/�ړ�No';
  gv_tkn_name_delivery_no     CONSTANT VARCHAR2(50) := '�z��No';
--
  gv_tkn_tbl_location_code    CONSTANT VARCHAR2(50) := '���Ə�';
  gv_tkn_tbl_eos_data_type    CONSTANT VARCHAR2(50) := 'EOS�f�[�^���';
--
  gv_tkn_itm_location_code    CONSTANT VARCHAR2(50) := '���Ə��R�[�h';
  gv_tkn_itm_eos_data_type    CONSTANT VARCHAR2(50) := '�R�[�h';
--
  gv_tbl_name_head            CONSTANT VARCHAR2(100) := '�o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)';
  gv_tbl_name_line            CONSTANT VARCHAR2(100) := '�o�׈˗��C���^�t�F�[�X����(�A�h�I��)';
--
  gv_title_head               CONSTANT VARCHAR2(50) := '�w�b�_�폜����';
  gv_title_line               CONSTANT VARCHAR2(50) := '���׍폜����';
  gv_title_count              CONSTANT VARCHAR2(50) := '��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE header_id_ttype        IS TABLE OF
    xxwsh_shipping_headers_if.header_id        %TYPE INDEX BY BINARY_INTEGER;  -- �w�b�_ID
  TYPE order_source_ref_ttype IS TABLE OF
    xxwsh_shipping_headers_if.order_source_ref %TYPE INDEX BY BINARY_INTEGER;  -- �󒍃\�[�X�Q��
  TYPE delivery_no_ttype      IS TABLE OF
    xxwsh_shipping_headers_if.delivery_no      %TYPE INDEX BY BINARY_INTEGER;  -- �z��No
  TYPE line_id_ttype          IS TABLE OF
    xxwsh_shipping_lines_if.line_id            %TYPE INDEX BY BINARY_INTEGER;  -- ����ID
--
  gt_header_id_del_tab      header_id_ttype;            -- �w�b�_ID
  gt_order_ref_del_tab      order_source_ref_ttype;     -- �󒍃\�[�X�Q��
  gt_delivery_no_del_tab    delivery_no_ttype;          -- �z��No
  gt_line_id_del_tab        line_id_ttype;              -- ����ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������                 (A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_location_code IN            VARCHAR2,   -- 1.�񍐕���                   --# �K�{ #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOS�f�[�^���              --# �K�{ #
    iv_order_ref     IN            VARCHAR2,   -- 3.�˗�No/�ړ�No              --# �C�� #
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    lv_description       xxcmn_locations_v.description%TYPE;   -- �񍐕�����
    lv_meaning           xxcmn_lookup_values_v.meaning%TYPE;   -- EOS�f�[�^��ʖ�
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
    -- �񍐕�����NULL
    IF (iv_location_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_01,
                                            gv_tkn_input,
                                            gv_tkn_name_location_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EOS�f�[�^��ʂ�NULL
    IF (iv_eos_data_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_01,
                                            gv_tkn_input,
                                            gv_tkn_name_eos_data_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �񍐕������擾
    BEGIN
      SELECT xlv.description
      INTO   lv_description
      FROM   xxcmn_locations_v xlv
      WHERE  xlv.location_code = iv_location_code
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_description := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �񍐕����������݂��Ȃ�
    IF (lv_description IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_02,
                                            gv_tkn_table,
                                            gv_tkn_tbl_location_code,
                                            gv_tkn_item,
                                            gv_tkn_itm_location_code,
                                            gv_tkn_key,
                                            iv_location_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- EOS�f�[�^��ʖ��擾
    BEGIN
      SELECT xlvv.meaning
      INTO   lv_meaning
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = gv_lookup_type
      AND    xlvv.lookup_code = iv_eos_data_type
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_meaning := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- EOS�f�[�^��ʖ������݂��Ȃ�
    IF (lv_meaning IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_number_93f_02,
                                            gv_tkn_table,
                                            gv_tkn_tbl_eos_data_type,
                                            gv_tkn_item,
                                            gv_tkn_itm_eos_data_type,
                                            gv_tkn_key,
                                            iv_eos_data_type);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_location_code||gv_msg_part||iv_location_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_eos_data_type||gv_msg_part||iv_eos_data_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_order_ref    ||gv_msg_part||iv_order_ref);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_del_data
   * Description      : �p�[�W�Ώے��o����       (A-2)
   ***********************************************************************************/
  PROCEDURE get_del_data(
    iv_location_code IN            VARCHAR2,   -- 1.�񍐕���                   --# �K�{ #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOS�f�[�^���              --# �K�{ #
    iv_order_ref     IN            VARCHAR2,   -- 3.�˗�No/�ړ�No              --# �C�� #
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_del_data'; -- �v���O������
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
    lv_tbl_name        VARCHAR2(100);
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
    -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�Ώێ擾
    BEGIN
      SELECT del.header_id                        -- �w�b�_ID
            ,del.order_source_ref                 -- �󒍃\�[�X�Q��
            ,del.delivery_no                      -- �z��No
      BULK COLLECT INTO gt_header_id_del_tab
                       ,gt_order_ref_del_tab
                       ,gt_delivery_no_del_tab
      FROM   xxwsh_shipping_headers_if base    -- ��f�[�^
            ,xxwsh_shipping_headers_if del     -- �폜�Ώ�
      WHERE  base.report_post_code = del.report_post_code                    -- �񍐕���
      AND    base.eos_data_type    = del.eos_data_type                       -- EOS�f�[�^���
      AND    base.delivery_no      = del.delivery_no                         -- �z��No
      AND    base.report_post_code = iv_location_code                        -- 1.�񍐕���
      AND    base.eos_data_type    = iv_eos_data_type                        -- 2.EOS�f�[�^���
      AND    base.order_source_ref = NVL(iv_order_ref,base.order_source_ref) -- 3.�˗�No/�ړ�No
      FOR UPDATE OF del.header_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_93f_03,
                                              gv_tkn_table,
                                              gv_tbl_name_head);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�Ώێ擾
    BEGIN
      SELECT line.line_id                         -- ����ID
      BULK COLLECT INTO gt_line_id_del_tab
      FROM   xxwsh_shipping_headers_if base    -- ��f�[�^
            ,xxwsh_shipping_headers_if del     -- �폜�Ώ�
            ,xxwsh_shipping_lines_if   line
      WHERE  base.report_post_code = del.report_post_code                    -- �񍐕���
      AND    base.eos_data_type    = del.eos_data_type                       -- EOS�f�[�^���
      AND    base.delivery_no      = del.delivery_no                         -- �z��No
      AND    line.header_id        = del.header_id                           -- �w�b�_ID
      AND    base.report_post_code = iv_location_code                        -- 1.�񍐕���
      AND    base.eos_data_type    = iv_eos_data_type                        -- 2.EOS�f�[�^���
      AND    base.order_source_ref = NVL(iv_order_ref,base.order_source_ref) -- 3.�˗�No/�ړ�No
      FOR UPDATE OF line.line_id NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_number_93f_03,
                                              gv_tkn_table,
                                              gv_tbl_name_line);
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_del_data;
--
  /**********************************************************************************
   * Procedure Name   : del_proc
   * Description      : �p�[�W����               (A-3)
   ***********************************************************************************/
  PROCEDURE del_proc(
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_proc'; -- �v���O������
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
    -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�폜
    FORALL item_cnt IN 1 .. gt_line_id_del_tab.COUNT
      DELETE FROM xxwsh_shipping_lines_if xslif
      WHERE xslif.line_id = gt_line_id_del_tab(item_cnt);
--
    -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜
    FORALL item_cnt IN 1 .. gt_header_id_del_tab.COUNT
      DELETE FROM xxwsh_shipping_headers_if xshif
      WHERE xshif.header_id = gt_header_id_del_tab(item_cnt);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_proc;
--
  /**********************************************************************************
   * Procedure Name   : term_proc
   * Description      : �I������                 (A-4)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf         OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- �v���O������
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
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_title_head||gv_msg_part||
                                      gt_header_id_del_tab.COUNT||gv_title_count);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_title_line||gv_msg_part||
                                      gt_line_id_del_tab.COUNT  ||gv_title_count);
--
    <<log_disp_loop>>
    FOR i IN 1 .. gt_header_id_del_tab.COUNT LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_delivery_no||gv_msg_part||
                                        gt_order_ref_del_tab(i));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_tkn_name_order_ref  ||gv_msg_part||
                                        gt_delivery_no_del_tab(i));
    END LOOP log_disp_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_location_code IN            VARCHAR2,   -- 1.�񍐕���                     --# �K�{ #
    iv_eos_data_type IN            VARCHAR2,   -- 2.EOS�f�[�^���                --# �K�{ #
    iv_order_ref     IN            VARCHAR2,   -- 3.�˗�No/�ړ�No                --# �C�� #
    ov_errbuf           OUT NOCOPY VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --*********************************************
    --***      ��������(A-1)                    ***
    --*********************************************
    init_proc(
      iv_location_code,  -- 1.�񍐕���
      iv_eos_data_type,  -- 2.EOS�f�[�^���
      iv_order_ref,      -- 3.�˗�No/�ړ�No
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �p�[�W�Ώے��o����(A-2)          ***
    --*********************************************
    get_del_data(
      iv_location_code,  -- 1.�񍐕���
      iv_eos_data_type,  -- 2.EOS�f�[�^���
      iv_order_ref,      -- 3.�˗�No/�ړ�No
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �p�[�W����(A-3)                  ***
    --*********************************************
    del_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      �I������(A-4)                    ***
    --*********************************************
    term_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf              OUT NOCOPY VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT NOCOPY VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_location_code IN            VARCHAR2,        -- 1.�񍐕���         #�K�{#
    iv_eos_data_type IN            VARCHAR2,        -- 2.EOS�f�[�^���    #�K�{#
    iv_order_ref     IN            VARCHAR2)        -- 3.�˗�No/�ړ�No    #�C��#
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���擾
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_location_code, -- 1.�񍐕���
      iv_eos_data_type, -- 2.EOS�f�[�^���
      iv_order_ref,     -- 3.�˗�No/�ړ�No
      lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh930006c;
/
