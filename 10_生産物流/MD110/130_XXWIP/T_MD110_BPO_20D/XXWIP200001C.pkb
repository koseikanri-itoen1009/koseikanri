CREATE OR REPLACE PACKAGE BODY xxwip200001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip200001c(body)
 * Description      : ���Y�o�b�`���_�E�����[�h
 * MD.050           : ���Y�o�b�` T_MD050_BPO_202
 * MD.070           : ���Y�o�b�`���_�E�����[�h T_MD070_BPO_20D
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init_proc           �O���� (D-1)
 *  get_data            �Ώۃf�[�^�擾 (D-2)
 *  output_csv          CSV�t�@�C���o�́F�������ʃ��|�[�g�o�� (D-4)
 *  set_batch_id        ���Y�o�b�`ID�i�[ (D-5)
 *  upd_send_type       ���M�σt���O�X�V (D-6)
 *  submain             ���C�������v���V�[�W��
 *  main                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/16    1.0  Oracle �쑺 ���K  ����쐬
 *  2008/06/18    1.1  Oracle ��r ���  ST�s��Ή�#160(���t�����C��)
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
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxwip200001c';    -- �p�b�P�[�W��
  gv_xxwip           CONSTANT VARCHAR2(100) := 'XXWIP';           -- �A�v���P�[�V�����Z�k��
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';           -- �A�v���P�[�V�����Z�k��
--
  gv_rep_file        CONSTANT VARCHAR2(1)   := '0';               -- �������ʃ��|�[�g
  gv_csv_file        CONSTANT VARCHAR2(1)   := '1';               -- CSV�t�@�C��
-- 
  -- �f�[�^�敪
  gt_data_type_add   CONSTANT VARCHAR2(1)   := '0';               -- �f�[�^�敪�F0�i�ǉ��j
  gt_data_type_mod   CONSTANT VARCHAR2(1)   := '1';               -- �f�[�^�敪�F1�i�����j
  gt_data_type_del   CONSTANT VARCHAR2(1)   := '2';               -- �f�[�^�敪�F2�i�폜�j
--
  -- ���b�Z�[�W
  gv_xxwip_nodata_err       CONSTANT VARCHAR2(100) := 'APP-XXWIP-10040';  -- �Ώۃf�[�^���擾�G���[
  gv_xxcom_noprof_err       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';  -- �v���t�@�C���擾�G���[
  gv_xxwip_table_lock_err   CONSTANT VARCHAR2(100) := 'APP-XXWIP-10029';  -- �e�[�u�����b�N�G���[
  gv_xxwip_output_nodir_err CONSTANT VARCHAR2(100) := 'APP-XXWIP-10041';  -- �o�͐�f�B���N�g���s�݃G���[
--
  -- �g�[�N��
  gv_tkn_ng_profile  CONSTANT VARCHAR2(100) := 'NG_PROFILE';        -- �g�[�N���FNG_PROFILE
  gv_tkn_table       CONSTANT VARCHAR2(100) := 'TABLE';             -- �g�[�N���FTABLE
  gv_tkn_target_name CONSTANT VARCHAR2(100) := 'TARGET_NAME';       -- �g�[�N���FTARGET_NAME
  gv_tkn_path        CONSTANT VARCHAR2(100) := 'PATH';              -- �g�[�N���FPATH
--
  --�v���t�@�C��
  gv_prf_out_dir     CONSTANT VARCHAR2(50) := 'XXWIP_BATCH_OUT_DIR';       -- �v���t�@�C���F�o�͐�
  gv_prf_out_file    CONSTANT VARCHAR2(50) := 'XXWIP_BATCH_OUT_FILE_NAME'; -- �v���t�@�C���F�o�̓t�@�C����
--
  -- ���Y�o�b�`�w�b�_ �Ɩ��X�e�[�^�X
  gt_oprtn_sts_cmp   CONSTANT gme_batch_header.attribute4%TYPE  := '6';     -- �Ɩ��X�e�[�^�X�F6 �i��t�ρj
  gt_oprtn_sts_can   CONSTANT gme_batch_header.attribute4%TYPE  := '-1';    -- �Ɩ��X�e�[�^�X�F-1�i����j
--
  -- ���Y�o�b�`�w�b�_ ���M�敪
  gt_send_type_non   CONSTANT gme_batch_header.attribute3%TYPE  := '0';     -- ���M�敪�F0�i�����M�j
  gt_send_type_cmp   CONSTANT gme_batch_header.attribute3%TYPE  := '1';     -- ���M�敪�F1�i���M�ρj
  gt_send_type_mod   CONSTANT gme_batch_header.attribute3%TYPE  := '2';     -- ���M�敪�F2�i�C���j
  gt_send_type_can   CONSTANT gme_batch_header.attribute3%TYPE  := '3';     -- ���M�敪�F3�i����j
--
  -- ���Y�����ڍ� ���C���^�C�v
  gt_compl_line_type  CONSTANT gme_material_details.line_type%TYPE := 1;    -- ���C���^�C�v�F1�i�����i�j
--
  -- �H���}�X�^ ���M�Ώۃt���O
  gt_send_flag_y      CONSTANT gmd_routings_b.attribute18%TYPE  := 'Y';     -- ���M�Ώۃt���O�FY�i���M�ρj
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���Y�o�b�`�����i�[���郌�R�[�h
  TYPE material_info_rec IS RECORD(
    batch_id              gme_batch_header.batch_id%TYPE,           -- �o�b�`ID
    plant_code            gme_batch_header.plant_code%TYPE,         -- �v�����g�R�[�h
    batch_no              gme_batch_header.batch_no%TYPE,           -- ��zNo
    item_no               xxcmn_item_mst_v.item_no%TYPE,            -- �i�ڃR�[�h
    routing_no            gmd_routings_b.routing_no%TYPE,           -- ���C��No
    location_code         gmd_routings_b.attribute9%TYPE,           -- �ۊǑq�ɃR�[�h
    plan_start_date       gme_batch_header.plan_start_date%TYPE,    -- ���Y�\���
    instruction_total     gme_material_details.attribute23%TYPE,    -- �w������
    send_type             gme_batch_header.attribute3%TYPE          -- ���M�敪
  );
--
  -- ���Y�o�b�`�����i�[����e�[�u���^�̒�`
  TYPE material_info_tbl IS TABLE OF material_info_rec INDEX BY PLS_INTEGER;
  -- �o�^�E�X�V�pPL/SQL�\�^
  TYPE batch_id_ttype   IS TABLE OF  gme_batch_header.batch_id%TYPE INDEX BY BINARY_INTEGER;  -- �o�b�`ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_material_info_tbl  material_info_tbl;  -- �����z��̒�`
  gt_batch_id_upd_tab      batch_id_ttype;     -- �o�b�`ID
  gd_sysdate            DATE;               -- �V�X�e�����ݓ��t
--
  gv_out_dir        VARCHAR2(150);          -- ���Y�o�b�`���o�͐�
  gv_out_file_name  VARCHAR2(150);          -- ���Y�o�b�`���t�@�C����
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �O���� (D-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_out_dir  CONSTANT VARCHAR2(30) := '���Y�o�b�`���o�͐�';
    cv_out_file CONSTANT VARCHAR2(30) := '���Y�o�b�`���t�@�C����';
--
    -- *** ���[�J���ϐ� ***
    ld_last_update  DATE;               -- �ŏI�X�V����
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
    -- **************************************************
    -- *** �O���[�o���ϐ�������
    -- **************************************************
    gv_out_dir := NULL;
    gv_out_file_name := NULL;
--
    -- **************************************************
    -- *** �v���t�@�C���擾�F���Y�o�b�`���o��
    -- **************************************************
    gv_out_dir := TRIM(FND_PROFILE.VALUE(gv_prf_out_dir));
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_out_dir IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            cv_out_dir);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �v���t�@�C���擾�F���Y�o�b�`���t�@�C����
    -- **************************************************
    gv_out_file_name := TRIM(FND_PROFILE.VALUE(gv_prf_out_file));
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_out_file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_xxcom_noprof_err,
                                            gv_tkn_ng_profile,
                                            cv_out_file);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END init_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �Ώۃf�[�^�擾 (D-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    cv_xxwip_batch_header     VARCHAR2(50) := '���Y�o�b�`�w�b�_';
--
    -- *** ���[�J���ϐ� ***
    ld_last_update  DATE;               -- �ŏI�X�V����
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
    -- **************************************************
    -- *** ���Y�o�b�`�����擾
    -- **************************************************
    SELECT gbh.batch_id,                -- �o�b�`ID
           gbh.plant_code,              -- �v�����g�R�[�h
           gbh.batch_no,                -- ��zNo
           ximv.item_no,                -- �i�ڃR�[�h
           grb.routing_no,              -- ���C��No
           grb.attribute9,              -- �ۊǑq�ɃR�[�h
           gbh.plan_start_date,         -- ���Y�\���
           gmd.attribute23,             -- �w������
           gbh.attribute3               -- ���M�σt���O
    BULK COLLECT INTO gt_material_info_tbl
    FROM  xxcmn_item_mst_v        ximv,     -- OPM�i�ڏ��VIEW
          gmd_routings_b          grb,      -- �H���}�X�^
          gme_material_details    gmd,      -- ���Y�����ڍ�
          gme_batch_header        gbh       -- ���Y�o�b�`�w�b�_
    WHERE gbh.batch_id            =   gmd.batch_id            -- �o�b�`ID
    AND   gbh.routing_id          =   grb.routing_id          -- �H��ID
    AND   gmd.item_id             =   ximv.item_id            -- �i��ID
    AND   gmd.line_type           =   gt_compl_line_type      -- ���C���^�C�v=�����i
    AND   grb.attribute18         =   gt_send_flag_y          -- ���M�Ώۃt���O=Y
    AND   gbh.attribute3          IN  (gt_send_type_non,      -- ���M�敪�F�����M
                                      gt_send_type_mod,       --         �F�C��
                                      gt_send_type_can)       --         �F���
    AND   ((gbh.attribute4        =   gt_oprtn_sts_cmp        -- �Ɩ��X�e�[�^�X=��t��
            AND   gbh.attribute3  <>  gt_send_type_cmp  )     -- ���M�敪<>���M��
    OR    (gbh.attribute4         =   gt_oprtn_sts_can        -- �Ɩ��X�e�[�^�X=�����
            AND   gbh.attribute3  =   gt_send_type_can  ))    -- ���M�敪=���
    ORDER BY gbh.batch_no                                     -- �o�b�`No
    FOR UPDATE OF gbh.batch_id NOWAIT;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
    WHEN lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxwip                      -- ���W���[�������́FXXWIP ���Y�E�i���Ǘ��E�^���v�Z
                    ,gv_xxwip_table_lock_err       -- ���b�Z�[�W�FAPP-XXWIP-10004 ���b�N�G���[�ڍ׃��b�Z�[�W
                    ,gv_tkn_table                  -- �g�[�N��TABLE
                    ,cv_xxwip_batch_header         -- �e�[�u�����F���Y�o�b�`�w�b�_
                    ),1,5000);
--
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
  END get_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�� (D-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- �t�@�C�����
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot    CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lf_file_hand    UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
    lv_csv_file     VARCHAR2(5000);        -- �o�͏��
    lv_data_type    VARCHAR2(1);           -- �f�[�^�敪
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �o�̓t�@�C���I�[�v��
    -- **************************************************
    -- CSV�t�@�C���o�͂̏ꍇ
    IF (iv_file_type = gv_csv_file) THEN
      lf_file_hand := UTL_FILE.FOPEN(gv_out_dir,        -- �f�B���N�g��
                                     gv_out_file_name,  -- �t�@�C����
                                     'w');              -- �����݃��[�h
    END IF;
--
    -- **************************************************
    -- *** ���Y�o�b�`��񂪎擾�ł��Ă���ꍇ
    -- **************************************************
    IF (gt_material_info_tbl.COUNT <> 0) THEN
--
      -- �t�@�C���o�̓��[�v
      <<gt_material_info_tbl_loop>>
      FOR i IN gt_material_info_tbl.FIRST .. gt_material_info_tbl.LAST LOOP
--
        -- **************************************************
        -- *** �f�[�^�敪�ҏW
        -- **************************************************
        -- �f�[�^�敪������
        lv_data_type := NULL;
--
        -- �����M�̏ꍇ
        IF (gt_material_info_tbl(i).send_type = gt_send_type_non) THEN
          lv_data_type := gt_data_type_add;
--
        -- �C���̏ꍇ
        ELSIF (gt_material_info_tbl(i).send_type = gt_send_type_mod) THEN
          lv_data_type := gt_data_type_mod;
--
        -- ����̏ꍇ
        ELSIF (gt_material_info_tbl(i).send_type = gt_send_type_can) THEN
          lv_data_type := gt_data_type_del;
        END IF;
--
        -- �擾�f�[�^CVS�`������
        lv_csv_file :=     cv_sep_wquot   || gt_material_info_tbl(i).plant_code  || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).batch_no || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).item_no || cv_sep_wquot 
                        || cv_sep_com 
-- 2008/06/18 D.Nihei MOD START
--                        || cv_sep_wquot   || TO_CHAR(gt_material_info_tbl(i).plan_start_date, 'YYYYMMDD') || cv_sep_wquot 
                        || cv_sep_wquot   || TO_CHAR(gt_material_info_tbl(i).plan_start_date, 'YYYY/MM/DD') || cv_sep_wquot 
-- 2008/06/18 D.Nihei MOD END
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).routing_no || cv_sep_wquot 
                        || cv_sep_com 
                        || cv_sep_wquot   || gt_material_info_tbl(i).location_code || cv_sep_wquot 
                        || cv_sep_com 
                        || gt_material_info_tbl(i).instruction_total 
                        || cv_sep_com 
                        || cv_sep_wquot   || lv_data_type || cv_sep_wquot;
--
        -- **************************************************
        -- *** �o�͏���
        -- **************************************************
        -- CVS�t�@�C���o�͂̏ꍇ
        IF (iv_file_type = gv_csv_file) THEN
          UTL_FILE.PUT_LINE(lf_file_hand, lv_csv_file);
--
        -- �������ʏo�͂̏ꍇ
        ELSIF (iv_file_type = gv_rep_file) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_csv_file);
--
        END IF;
      END LOOP gt_material_info_tbl_loop;
--
      -- **************************************************
      -- *** CSV�t�@�C���N���[�Y
      -- **************************************************
      -- CSV�t�@�C���o�͂̏ꍇ
      IF (iv_file_type = gv_csv_file) THEN
        IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
          UTL_FILE.FCLOSE(lf_file_hand);
        END IF;
      END IF;
--
    END IF;
--
  --==============================================================
  --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
  --==============================================================
--
  EXCEPTION
--
    -- �t�@�C���p�X�s���G���[
    WHEN UTL_FILE.INVALID_PATH THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    --�t�@�C�����s���G���[
    WHEN UTL_FILE.INVALID_FILENAME THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    --�t�@�C���A�N�Z�X�����G���[
    WHEN UTL_FILE.ACCESS_DENIED THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwip,
                                            gv_xxwip_output_nodir_err,
                                            gv_tkn_target_name,
                                            gv_out_file_name,
                                            gv_tkn_path,
                                            gv_out_dir);
      lv_errbuf :=  lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
--
  /**********************************************************************************
   * Procedure Name   : set_batch_id
   * Description      : ���Y�o�b�`ID�i�[ (D-5)
   ***********************************************************************************/
  PROCEDURE set_batch_id(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_type'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώۃf�[�^��0���ȊO�̏ꍇ
    IF gt_material_info_tbl.COUNT <> 0 THEN
--
      -- **************************************************
      -- *** �o�b�`ID�i�[
      -- **************************************************
      <<batch_id_upd_tab_loop>>
      FOR i IN gt_material_info_tbl.FIRST .. gt_material_info_tbl.LAST LOOP
        gt_batch_id_upd_tab(i) := gt_material_info_tbl(i).batch_id;
      END LOOP batch_id_upd_tab_loop;
--
    END IF;
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
  END set_batch_id;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_send_type
   * Description      : ���M�σt���O�X�V (D-6)
   ***********************************************************************************/
  PROCEDURE upd_send_type(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_send_type'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������0���ȊO�̏ꍇ
    IF gt_batch_id_upd_tab.COUNT <> 0 THEN
--
      -- **************************************************
      -- *** ���M�σt���O�X�V�ꊇ�X�V����
      -- **************************************************
      FORALL ln_cnt_loop IN gt_batch_id_upd_tab.FIRST .. gt_batch_id_upd_tab.LAST
        UPDATE gme_batch_header         -- ���Y�o�b�`�w�b�_
        SET    attribute3               = gt_send_type_cmp                -- ���M�敪�i���M�ς݁j
              ,last_updated_by          = FND_GLOBAL.USER_ID              -- �ŏI�X�V��
              ,last_update_date         = SYSDATE                         -- �ŏI�X�V��
              ,last_update_login        = FND_GLOBAL.LOGIN_ID             -- �ŏI�X�V���O�C��
        WHERE batch_id = gt_batch_id_upd_tab(ln_cnt_loop);                   -- �o�b�`ID
--
  END IF;
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
  END upd_send_type;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_out_par    VARCHAR2(1000);   -- ���̓p�����[�^�o��
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;       -- �Ώی���
    gn_normal_cnt := 0;       -- ���팏��
    gn_error_cnt  := 0;       -- �G���[����
    gn_warn_cnt   := 0;       -- �X�L�b�v����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������
    -- ===============================
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate := SYSDATE;
--
    -- ===============================
    -- �O���� (D-1)
    -- ===============================
    init_proc(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^�擾 (D-2)
    -- ===============================
    get_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- *******************************
    -- *** �Ώی��� �ݒ�
    -- *******************************
    gn_target_cnt := gt_material_info_tbl.COUNT;
--
    -- ===============================
    -- �������ʃ��|�[�g�o�� (D-4)
    -- ===============================
    output_csv(
      gv_rep_file,        -- ������ʁF�������ʃ��|�[�g
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSV�t�@�C���o�� (D-4)
    -- ===============================
    output_csv(
      gv_csv_file,        -- ������ʁFCSV�t�@�C���o��
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���Y�o�b�`ID�i�[ (D-5)
    -- ===============================
    set_batch_id(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���M�σt���O�X�V (D-6)
    -- ===============================
    upd_send_type(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- *******************************
    -- *** ���팏�� �ݒ�
    -- *******************************
    gn_normal_cnt := gt_material_info_tbl.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwip200001c;
/
