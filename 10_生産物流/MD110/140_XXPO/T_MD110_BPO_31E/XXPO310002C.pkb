CREATE OR REPLACE PACKAGE BODY xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(body)
 * Description      : HHT�������IF
 * MD.050           : �������            T_MD050_BPO_310
 * MD.070           : HHT�������IF       T_MD070_BPO_31E
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_proc              �O����                                       (E-1)
 *  parameter_check        �p�����[�^�`�F�b�N                           (E-2)
 *  get_mast_data          �������擾                                 (E-3)
 *  create_csv_file        ����\����o��                             (E-4)
 *  disp_report            �����o��                                     (E-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/21    1.1   Oracle �R�� ��_ �ύX�v��No43�Ή�
 *  2008/05/23    1.2   Oracle ���� �Ǖ� �����e�X�g�s��i�V�i���I4-1�j
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxpo310002c';   -- �p�b�P�[�W��
  gv_app_name            CONSTANT VARCHAR2(5)   := 'XXPO';          -- �A�v���P�[�V�����Z�k��
--
  gv_status_po_zumi      CONSTANT VARCHAR2(2)   := '20';            -- �����쐬��
  gv_status_money_zumi   CONSTANT VARCHAR2(2)   := '35';            -- ���z�m���
  gv_class_code_seihin   CONSTANT VARCHAR2(1)   := '5';             -- ���i
--
  -- �g�[�N��
  gv_tkn_number_31e_01    CONSTANT VARCHAR2(15) := 'APP-XXPO-10062';  -- ����\����̧�ٖ��擾�װ
  gv_tkn_number_31e_02    CONSTANT VARCHAR2(15) := 'APP-XXPO-10063';  -- ����\��������ݴװ
  gv_tkn_number_31e_03    CONSTANT VARCHAR2(15) := 'APP-XXPO-10064';  -- ����\����o�͐�擾�װ
  gv_tkn_number_31e_04    CONSTANT VARCHAR2(15) := 'APP-XXPO-10065';  -- �o�͐��ިڸ�ؕs���ݴװ
  gv_tkn_number_31e_05    CONSTANT VARCHAR2(15) := 'APP-XXPO-10093';  -- ������񖢎擾�װ
  gv_tkn_number_31e_06    CONSTANT VARCHAR2(15) := 'APP-XXPO-10102';  -- �s�������Ұ�1
  gv_tkn_number_31e_07    CONSTANT VARCHAR2(15) := 'APP-XXPO-10103';  -- �s�������Ұ�2
  gv_tkn_number_31e_08    CONSTANT VARCHAR2(15) := 'APP-XXPO-10104';  -- �s�������Ұ�3
  gv_tkn_number_31e_09    CONSTANT VARCHAR2(15) := 'APP-XXPO-10106';  -- �s�������Ұ�5
  gv_tkn_number_31e_10    CONSTANT VARCHAR2(15) := 'APP-XXPO-30027';  -- ��������
  gv_tkn_number_31e_11    CONSTANT VARCHAR2(15) := 'APP-XXPO-30035';  -- �������Ұ����1
--
  gv_tkn_count            CONSTANT VARCHAR2(15) := 'COUNT';
  gv_tkn_date_from        CONSTANT VARCHAR2(15) := 'DATE_FROM';
  gv_tkn_date_to          CONSTANT VARCHAR2(15) := 'DATE_TO';
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAM_NAME';
  gv_tkn_param_value      CONSTANT VARCHAR2(15) := 'PARAM_VALUE';
  gv_tkn_path             CONSTANT VARCHAR2(15) := 'PATH';
  gv_tkn_ship             CONSTANT VARCHAR2(15) := 'SHIP';
  gv_tkn_vendor           CONSTANT VARCHAR2(15) := 'VENDOR';
--
  gv_tkn_2byte_date_from  CONSTANT VARCHAR2(50) := '�[����(FROM)';
  gv_tkn_2byte_date_to    CONSTANT VARCHAR2(50) := '�[����(TO)';
  gv_tkn_2byte_ship       CONSTANT VARCHAR2(50) := '�[����';
  gv_tkn_2byte_vendor     CONSTANT VARCHAR2(50) := '�����';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- D-3:�������擾�Ώۃf�[�^
  TYPE masters_rec IS RECORD(
    po_header_number    po_headers_all.segment1%TYPE,               -- �����ԍ�
    segment1            xxcmn_vendors_v.segment1%TYPE,              -- �d����ԍ�
    vendor_short_name   xxcmn_vendors_v.vendor_short_name%TYPE,     -- ����(����於)
    attribute4          po_headers_all.attribute4%TYPE,             -- �[����
    attribute5          po_headers_all.attribute5%TYPE,             -- �[����R�[�h
    description         xxcmn_item_locations_v.description%TYPE,    -- �E�v(�[���於)
    line_num            po_lines_all.line_num%TYPE,                 -- ���הԍ�
    item_no             xxcmn_item_mst_v.item_no%TYPE,              -- �i��
    item_short_name     xxcmn_item_mst_v.item_short_name%TYPE,      -- ����(�i����)
    lot_no              po_lines_all.attribute1%TYPE,               -- ���b�gNo
    attribute1          ic_lots_mst.attribute1%TYPE,                -- �����N����
    attribute2          ic_lots_mst.attribute2%TYPE,                -- �ŗL�L��
    attribute11         po_lines_all.attribute11%TYPE,              -- ��������
    attribute10         po_lines_all.attribute10%TYPE,              -- �����P��
    attribute15         po_lines_all.attribute15%TYPE,              -- ���דE�v
--
    exec_flg            NUMBER                                      -- �����t���O
  );
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_rcv_sch_out_dir          VARCHAR2(2000);             -- XXPO:����\����o�͐�
  gv_rcv_sch_file_name        VARCHAR2(2000);             -- XXPO:����\����t�@�C����
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �O����(E-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'init_proc';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ����\����o�͐�
    gv_rcv_sch_out_dir := FND_PROFILE.VALUE('XXPO_RCV_SCH_OUT_DIR');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_rcv_sch_out_dir IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_03);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ����\����t�@�C����
    gv_rcv_sch_file_name := FND_PROFILE.VALUE('XXPO_RCV_SCH_FILE_NAME');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_rcv_sch_file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_01);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(E-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_from_date   IN            VARCHAR2,     -- 1.�[����(FROM)
    iv_to_date     IN            VARCHAR2,     -- 2.�[����(TO)
    iv_inv_code    IN            VARCHAR2,     -- 3.�[����R�[�h
    iv_vendor_id   IN            VARCHAR2,     -- 4.�����R�[�h
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_from_date       DATE;
    ld_to_date         DATE;
    ln_cnt             NUMBER;
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
    -- �[���悪������
    IF (iv_inv_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_ship);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����(FROM)��������
    IF (iv_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����(TO)��������
    IF (iv_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_06,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���t�ɕϊ�
    ld_from_date := FND_DATE.STRING_TO_DATE(iv_from_date,'YYYY/MM/DD');
--
    -- ���t�Ƃ��đÓ��łȂ�
    IF (ld_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_08,
                                              gv_tkn_param_value,
                                              iv_from_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���t�ɕϊ�
    ld_to_date := FND_DATE.STRING_TO_DATE(iv_to_date,'YYYY/MM/DD');
--
    -- ���t�Ƃ��đÓ��łȂ�
    IF (ld_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_08,
                                            gv_tkn_param_value,
                                            iv_to_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����(FROM) > �[����(TO)
    IF (ld_from_date > ld_to_date) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_09);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �[����R�[�h�`�F�b�N
    SELECT COUNT(xilv.segment1)
    INTO   ln_cnt
    FROM   xxcmn_item_locations_v xilv                  -- OPM�ۊǏꏊ���VIEW
    WHERE  xilv.segment1 = iv_inv_code
    AND    ROWNUM        = 1;
--
    -- �[����R�[�h���Ȃ�
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_07,
                                            gv_tkn_param_name,
                                            gv_tkn_2byte_ship,
                                            gv_tkn_param_value,
                                            iv_inv_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ����悪�w�肠��
    IF (iv_vendor_id IS NOT NULL) THEN
      SELECT COUNT(xvv.segment1)
      INTO   ln_cnt
      FROM   xxcmn_vendors_v xvv                        -- �d������VIEW
      WHERE  xvv.segment1 = iv_vendor_id
      AND    ROWNUM       = 1;
--
      -- �����R�[�h���Ȃ�
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_07,
                                              gv_tkn_param_name,
                                              gv_tkn_2byte_vendor,
                                              gv_tkn_param_value,
                                              iv_vendor_id);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���̓p�����[�^�\��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31e_11,
                                          gv_tkn_vendor,
                                          iv_vendor_id,
                                          gv_tkn_ship,
                                          iv_inv_code,
                                          gv_tkn_date_from,
                                          iv_from_date,
                                          gv_tkn_date_to,
                                          iv_to_date);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
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
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : get_mast_data
   * Description      : �������擾(E-3)
   ***********************************************************************************/
  PROCEDURE get_mast_data(
    iv_from_date   IN            VARCHAR2,     -- 1.�[����(FROM)
    iv_to_date     IN            VARCHAR2,     -- 2.�[����(TO)
    iv_inv_code    IN            VARCHAR2,     -- 3.�[����R�[�h
    iv_vendor_id   IN            VARCHAR2,     -- 4.�����R�[�h
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_mast_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER;
    mst_rec           masters_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
      SELECT pha.segment1 as po_header_number              -- �����ԍ�
            ,pha.attribute4                                -- �[����
            ,pha.attribute5                                -- �[����R�[�h
            ,pla.line_num                                  -- ���הԍ�
            ,pla.attribute1 as lot_no                      -- ���b�gNo
            ,pla.attribute11                               -- ��������
            ,pla.attribute10                               -- �����P��
            ,pla.attribute15                               -- ���דE�v
            ,xiv.item_no                                   -- �i�ڃR�[�h
            ,xiv.item_short_name                           -- ����(�i����)
            ,ilm.attribute1                                -- �����N����
            ,ilm.attribute2                                -- �ŗL�L��
            ,xvv.segment1                                  -- �d����ԍ�
            ,xvv.vendor_short_name                         -- ����(����於)
            ,xilv.description                              -- �E�v(�[���於)
      FROM   po_headers_all pha                  -- �����w�b�_
            ,po_lines_all pla                    -- ��������
            ,xxcmn_item_mst_v xiv                -- OPM�i�ڏ��VIEW
            ,ic_lots_mst ilm                     -- OPM���b�g�}�X�^
            ,xxcmn_vendors_v xvv                 -- �d������VIEW
            ,xxcmn_item_locations_v xilv         -- OPM�ۊǏꏊ���VIEW
      WHERE  pha.po_header_id = pla.po_header_id
      AND    pla.item_id      = xiv.inventory_item_id
      AND    pla.attribute1   = ilm.lot_no
      AND    xiv.item_id      = ilm.item_id
      AND    pha.vendor_id    = xvv.vendor_id
      AND    pha.attribute5   = xilv.segment1
      AND   ((iv_vendor_id IS NULL)
      OR     (xvv.segment1    = iv_vendor_id))
      AND    pha.attribute5   = iv_inv_code
      AND    pha.attribute4   >= iv_from_date
      AND    pha.attribute4   <= iv_to_date
      AND    pha.attribute1   >= gv_status_po_zumi                   -- �����쐬��:20
      AND    pha.attribute1   < gv_status_money_zumi                 -- ���z�m���:35
      AND   NOT EXISTS (
        SELECT plav.po_header_id
        FROM   po_lines_all plav                 -- ��������
              ,xxcmn_item_mst_v xiv              -- OPM�i�ڏ��VIEW
              ,xxcmn_item_categories3_v xic      -- OPM�i�ڃJ�e�S��VIEW3
        WHERE  plav.po_header_id = pla.po_header_id
        AND    plav.item_id      = xiv.inventory_item_id
        AND    xiv.item_id       = xic.item_id
-- 2008/05/23 v1.2 Add
        AND    plav.cancel_flag  = 'N'
-- 2008/05/23 v1.2 Add
        AND    NVL(xic.item_class_code,'0') <> gv_class_code_seihin  -- ���i:5
      )
      ORDER BY pha.segment1,pla.line_num;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.po_header_number  := lr_mst_data_rec.po_header_number;
      mst_rec.attribute4        := lr_mst_data_rec.attribute4;
      mst_rec.attribute5        := lr_mst_data_rec.attribute5;
      mst_rec.line_num          := lr_mst_data_rec.line_num;
      mst_rec.lot_no            := lr_mst_data_rec.lot_no;
      mst_rec.attribute11       := lr_mst_data_rec.attribute11;
      mst_rec.attribute10       := lr_mst_data_rec.attribute10;
      mst_rec.attribute15       := lr_mst_data_rec.attribute15;
      mst_rec.item_no           := lr_mst_data_rec.item_no;
      mst_rec.item_short_name   := lr_mst_data_rec.item_short_name;
      mst_rec.attribute1        := lr_mst_data_rec.attribute1;
      mst_rec.attribute2        := lr_mst_data_rec.attribute2;
      mst_rec.segment1          := lr_mst_data_rec.segment1;
      mst_rec.vendor_short_name := lr_mst_data_rec.vendor_short_name;
      mst_rec.description       := lr_mst_data_rec.description;
--
      gt_master_tbl(ln_cnt)     := mst_rec;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_mast_data;
--
  /***********************************************************************************
   * Procedure Name   : create_csv_file
   * Description      : ����\����o��(E-4)
   ***********************************************************************************/
  PROCEDURE create_csv_file(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_file';           -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
--
    -- *** ���[�J���ϐ� ***
    mst_rec         masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- �t�@�C���E�n���h���̐錾
--
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gv_rcv_sch_out_dir,
                      gv_rcv_sch_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C������
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_number_31e_02);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
      -- �t�@�C���I�[�v��
      lf_file_hand := UTL_FILE.FOPEN(gv_rcv_sch_out_dir,
                                     gv_rcv_sch_file_name,
                                     'w');
--
      -- �f�[�^����
      IF (gt_master_tbl.COUNT > 0) THEN
--
        <<file_put_loop>>
        FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
          mst_rec := gt_master_tbl(i);
--
          -- �f�[�^�쐬
          lv_data := mst_rec.po_header_number  || cv_sep_com ||        -- �����ԍ�
                     mst_rec.segment1          || cv_sep_com ||        -- �d����ԍ�
                     mst_rec.vendor_short_name || cv_sep_com ||        -- ����(����於)
                     mst_rec.attribute4        || cv_sep_com ||        -- �[����
                     mst_rec.attribute5        || cv_sep_com ||        -- �[����R�[�h
                     mst_rec.description       || cv_sep_com ||        -- �E�v(�[���於)
                     mst_rec.line_num          || cv_sep_com ||        -- ���הԍ�
                     mst_rec.item_no           || cv_sep_com ||        -- �i��
                     mst_rec.item_short_name   || cv_sep_com ||        -- ����(�i����)
                     mst_rec.lot_no            || cv_sep_com ||        -- ���b�gNo
                     mst_rec.attribute1        || cv_sep_com ||        -- �����N����
                     mst_rec.attribute2        || cv_sep_com ||        -- �ŗL�L��
                     mst_rec.attribute11       || cv_sep_com ||        -- ��������
                     mst_rec.attribute10       || cv_sep_com ||        -- �����P��
                     mst_rec.attribute15;                              -- ���דE�v
--
          -- �f�[�^�o��
          UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
        END LOOP file_put_loop;
--
      -- �f�[�^�Ȃ�
      ELSE
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_05);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH OR         -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_FILENAME OR     -- �t�@�C�����s���G���[
           UTL_FILE.ACCESS_DENIED OR        -- �t�@�C���A�N�Z�X�����G���[
           UTL_FILE.WRITE_ERROR THEN        -- �������݃G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_tkn_number_31e_04,
                                              gv_tkn_path,
                                              gv_rcv_sch_out_dir);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_csv_file;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : �������ʃ��|�[�g�o��(E-5)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count       NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    ln_count := gt_master_tbl.COUNT;
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_number_31e_10,
                                          gv_tkn_count,
                                          TO_CHAR(ln_count));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_from_date  IN            VARCHAR2,     -- 1.�[����(FROM)
    iv_to_date    IN            VARCHAR2,     -- 2.�[����(TO)
    iv_inv_code   IN            VARCHAR2,     -- 3.�[����R�[�h
    iv_vendor_id  IN            VARCHAR2,     -- 4.�����R�[�h
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    -- ================================
    -- E-1.�O����
    -- ================================
    init_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-2.�p�����[�^�`�F�b�N
    -- ================================
    parameter_check(
      iv_from_date,       -- 1.�[����(FROM)
      iv_to_date,         -- 2.�[����(TO)
      iv_inv_code,        -- 3.�[����R�[�h
      iv_vendor_id,       -- 4.�����R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-3.�������擾
    -- ================================
    get_mast_data(
      iv_from_date,       -- 1.�[����(FROM)
      iv_to_date,         -- 2.�[����(TO)
      iv_inv_code,        -- 3.�[����R�[�h
      iv_vendor_id,       -- 4.�����R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-4.����\����o��
    -- ================================
    create_csv_file(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- E-5.�����o��
    -- ================================
    disp_report(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf           OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT NOCOPY VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_from_date  IN            VARCHAR2,         -- 1.�[����(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.�[����(TO)
    iv_inv_code   IN            VARCHAR2,         -- 3.�[����R�[�h
    iv_vendor_id  IN            VARCHAR2)         -- 4.�����R�[�h
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
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_from_date,         -- 1.�[����(FROM)
      iv_to_date,           -- 2.�[����(TO)
      iv_inv_code,          -- 3.�[����R�[�h
      iv_vendor_id,         -- 4.�����R�[�h
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
/*
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
*/
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
END xxpo310002c;
/
