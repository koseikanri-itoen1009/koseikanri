create or replace
PACKAGE BODY XXCFF004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A10C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �ă��[�X�v�ۃA�b�v���[�h CFF_004_A10
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_if_data            p �t�@�C���A�b�v���[�hIF�f�[�^�擾����    (A-2)
 *  devide_item            p �f���~�^�������ڕ���                    (A-3)
 *  insert_work            p �ă��[�X�v�ۃ��[�N�f�[�^�쐬            (A-5)
 *  combination_check      p �g�ݍ��킹�`�F�b�N                      (A-6)
 *  item_validate_check    p ���ڑÓ����`�F�b�N                      (A-8)
 *  re_lease_update        p �������R�[�h���b�N�ƍX�V                (A-9)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/02    1.0   SCS��� �M�K     �V�K�쐬
 *  2009/02/09    1.1   SCS��� �M�K     ���O�o�͍��ڒǉ�
 *  2009/02/25    1.2   SCS��� �M�K     �����񒆂�"��؂���
 *  2009/02/25    1.3   SCS��� �M�K     ���[�U�[���b�Z�[�W�o�͐�ύX
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
  gr_file_data_tbl xxccp_common_pkg2.g_file_data_tbl; --�t�@�C���A�b�v���[�h�f�[�^�i�[�z��
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
---- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A10C'; -- �p�b�P�[�W��
  cv_log             CONSTANT VARCHAR2(100) := 'LOG';          -- �R���J�����g���O�o�͐�--
  cv_out             CONSTANT VARCHAR2(100) := 'OUTPUT';            -- �R���J�����g�o�͐�--
--
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';            -- �A�h�I���F��v�E���[�X�EFA�̈�
  cv_appl_name_cmn   CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
  cv_not_null_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00005'; -- �K�{�G���[���b�Z�[�W
  cv_num_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00117'; -- ���l�G���[���b�Z�[�W
  cv_combi_msg       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00036'; -- �g�ݍ��킹�G���[���b�Z�[�W
  cv_exp_date_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00033'; -- �������G���[���b�Z�[�W
  cv_obj_stat_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00063'; -- �����X�e�[�^�X�G���[���b�Z�[�W
  cv_re_lease_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00051'; -- �ă��[�X�v�ےl�G���[���b�Z�[�W
  cv_rec_lock_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00007'; -- ���R�[�h���b�N�G���[���b�Z�[�W
  cv_dup_index_msg   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00011'; -- �d���G���[���b�Z�[�W
  cv_format_msg      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00166'; -- ���ڃt�H�[�}�b�g�G���[���b�Z�[�W
  cv_upload_init_msg CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00167'; -- �A�b�v���[�h�����o�̓��b�Z�[�W
--
  cv_not_null_tkn    CONSTANT VARCHAR2(100)  := 'COLUMN_NAME';     -- �K�{�G���[�g�[�N��
  cv_col_nam_tkn     CONSTANT VARCHAR2(100)  := 'COLUMN_VALUE';    -- ���ڒl�g�[�N��
  cv_info_tkn        CONSTANT VARCHAR2(100)  := 'INFO';            -- ���g�[�N��
  cv_from_info_tkn   CONSTANT VARCHAR2(100)  := 'FROM_INFO';       -- ���g�[�N��
  cv_num_err_tkn     CONSTANT VARCHAR2(100)  := 'INPUT';           -- ���l�G���[�g�[�N��
  cv_combi_tkn1      CONSTANT VARCHAR2(100)  := 'OBJECT_CODE';     -- �g�ݍ��킹�G���[�g�[�N��
  cv_combi_tkn2      CONSTANT VARCHAR2(100)  := 'CONTACT_NUMBER';  -- �g�ݍ��킹�G���[�g�[�N��
  cv_combi_tkn3      CONSTANT VARCHAR2(100)  := 'CONTACT_NUM';     -- �g�ݍ��킹�G���[�g�[�N��
  cv_combi_tkn4      CONSTANT VARCHAR2(100)  := 'LEASE_COMPANY';   -- �g�ݍ��킹�G���[�g�[�N��
  cv_combi_tkn5      CONSTANT VARCHAR2(100)  := 'LEASE_TIMES';     -- �g�ݍ��킹�G���[�g�[�N��
  cv_exp_tkn1        CONSTANT VARCHAR2(100)  := 'EXPIRATION_DATE'; -- �������G���[�g�[�N��
  cv_exp_tkn2        CONSTANT VARCHAR2(100)  := 'BATCH_DATE';      -- �������G���[�g�[�N��
  cv_status_tkn      CONSTANT VARCHAR2(100)  := 'OBJECT_STATUS';   -- �����X�e�[�^�X�G���[�g�[�N��
  cv_re_lease_tkn    CONSTANT VARCHAR2(100)  := 'RE_LEASED_FLAG';  -- �ă��[�X�l�G���[�g�[�N��
  cv_rec_lock_tkn    CONSTANT VARCHAR2(100)  := 'TABLE_NAME';      -- ���R�[�h���b�N�g�[�N��
  cv_file_name_tkn   CONSTANT VARCHAR2(100)  := 'FILE_NAME';       -- �t�@�C�����g�[�N��
  cv_csv_name_tkn    CONSTANT VARCHAR2(100)  := 'CSV_NAME';        -- CSV�t�@�C�����g�[�N��
  cv_csv_name        CONSTANT VARCHAR2(3)    := 'CSV';             -- CSV
  cv_csv_delim       CONSTANT VARCHAR2(3)    := ',';               -- CSV��؂蕶��
  cv_look_type       CONSTANT VARCHAR2(100)  := 'XXCFF1_RE_LEASE_UPLOAD'; -- LOOKUP TYPE
--
  cv_tkn_val1        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50010'; -- �����R�[�h
  cv_tkn_val2        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50020'; -- �ă��[�X�v�t���O
  cv_tkn_val3        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50044'; -- �ă��[�X��
  cv_tkn_val4        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50040'; -- �_��ԍ�
  cv_tkn_val5        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50058'; -- �_��}��
  cv_tkn_val6        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50013'; -- �����X�e�[�^�X
  cv_tkn_val7        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50014'; -- ���[�X�����e�[�u��
  cv_tkn_val8        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50136'; -- �A�b�v���[�h�t�@�C���ă��[�X�v��
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,              -- 1.�t�@�C��ID
    or_init_rec   OUT NOCOPY xxcff_common1_pkg.init_rtype,  -- 2.�������i�[
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- �G���[�E���b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_which         => cv_out              -- �o�͋敪
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;

--    �A�b�v���[�hCSV�t�@�C�����擾
      SELECT
             file_name
      INTO
             lv_file_name
      FROM
             xxccp_mrp_file_ul_interface
      WHERE
            file_id = in_file_id;

--    �A�b�v���[�hCSV�t�@�C�������O�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_upload_init_msg
                                          ,cv_file_name_tkn,   cv_tkn_val8
                                          ,cv_csv_name_tkn,    lv_file_name)
      );

    -- ���ʏ��������̌Ăяo��
    xxcff_common1_pkg.init(
       ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
      ,or_init_rec => or_init_rec   --   1.�������i�[
    );

    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id    IN  NUMBER,              --   1.�t�@�C��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --���ʃA�b�v���[�h�f�[�^�ϊ�����
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id =>  in_file_id       -- �t�@�C���h�c
      ,ov_file_data=> gr_file_data_tbl -- �ϊ���VARCHAR2�f�[�^
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
    );
--lv_retcode := cv_status_error;
--lv_errmsg := '�ُ�I���m�F�̂��߃��[�U�[�G���[�Ƃ��Đݒ�';
--lv_errbuf := '�A�b�v���[�h�f�[�^�ϊ������ŃG���[�i�e�X�g�p�ɕύX�j';
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
  END get_if_data;
  /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : �f���~�^�������ڕ���(A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    in_file_data  IN  VARCHAR2,                           --  1.�t�@�C���f�[�^
    ov_flag       OUT NOCOPY VARCHAR2,                    --  2.�f�[�^�敪
    or_work_rtype OUT NOCOPY xxcff_re_lease_work%ROWTYPE, --  3.�ă��[�X�v�ۃ��[�N���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'devide_item'; -- �v���O������
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
    lv_item        VARCHAR2(5000);   -- ���ڈꎞ�i�[�p
    lv_errmsg_sv   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W�i�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR item_check_cur(in_type VARCHAR2)
    IS
    SELECT
           flv.lookup_code           AS lookup_code
          ,TO_NUMBER(flv.meaning)    AS index_num
          ,flv.description           AS item_name
          ,TO_NUMBER(flv.attribute1) AS item_len
          ,TO_NUMBER(flv.attribute2) AS item_dec
          ,flv.attribute3            AS item_null
          ,flv.attribute4            AS item_type
    FROM   fnd_lookup_values_vl flv
    WHERE  lookup_type = in_type
    ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
    item_check_cur_rec item_check_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_errmsg_sv := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN item_check_cur(cv_look_type);
    LOOP
      FETCH item_check_cur INTO item_check_cur_rec;
      EXIT WHEN item_check_cur%NOTFOUND;
      -- INDEX�Ԗڂ̃f�[�^�擾
      lv_item :=
        xxccp_common_pkg.char_delim_partition(in_file_data
                                             ,cv_csv_delim
                                             ,item_check_cur_rec.index_num
        );
      -- �͂ݕ����́h��TRIM����
      lv_item := ltrim(lv_item,'"');
      lv_item := rtrim(lv_item,'"');
      -- =====================================================
      --  ���ڒ��A�K�{�A�f�[�^�^�G���[�`�F�b�N
      -- =====================================================
      xxccp_common_pkg2.upload_item_check(
        iv_item_name     => item_check_cur_rec.item_name, -- ���ږ��́i���ڂ̓��{�ꖼ�j  -- �K�{
        iv_item_value    => lv_item,       -- ���ڂ̒l                    -- �C��
        in_item_len      => item_check_cur_rec.item_len,  -- ���ڂ̒���                  -- �K�{
        in_item_decimal  => item_check_cur_rec.item_dec,  -- ���ڂ̒����i�����_�ȉ��j    -- �����t�K�{
        iv_item_nullflg  => item_check_cur_rec.item_null, -- �K�{�t���O�i��L�萔��ݒ�j-- �K�{
        iv_item_attr     => item_check_cur_rec.item_type, -- ���ڑ����i��L�萔��ݒ�j  -- �K�{
        ov_errbuf        => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode       => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg        => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #

      IF (lv_errmsg IS NOT NULL)
        AND (lv_errmsg_sv IS NULL) THEN
        lv_errmsg_sv := lv_errmsg;
      ELSE
        CASE item_check_cur_rec.lookup_code
          WHEN 1 THEN
            ov_flag := TRIM(lv_item);
          WHEN 2 THEN
            or_work_rtype.object_code := lv_item;
          WHEN 3 THEN
            or_work_rtype.re_lease_flag := lv_item;
          WHEN 4 THEN
            or_work_rtype.contract_number := lv_item;
          WHEN 5 THEN
            or_work_rtype.contract_line_num := TO_NUMBER(lv_item);
          WHEN 6 THEN
            or_work_rtype.lease_company := lv_item;
          WHEN 7 THEN
            or_work_rtype.re_lease_times := TO_NUMBER(lv_item);
        END CASE ;
      END IF;
      IF (ov_flag IS NULL) THEN
        CLOSE item_check_cur;
        EXIT;
      END IF;

    END LOOP;
    IF (lv_errmsg_sv IS NOT NULL) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_format_msg
                                          ,cv_info_tkn,        lv_errmsg_sv
                                          ,cv_combi_tkn1,      or_work_rtype.object_code
                                          ,cv_combi_tkn2,      or_work_rtype.contract_number
                                          ,cv_combi_tkn3,      or_work_rtype.contract_line_num
                                          ,cv_combi_tkn4,      or_work_rtype.lease_company
                                          ,cv_combi_tkn5,      or_work_rtype.re_lease_times)
      );
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (item_check_cur%ISOPEN) THEN
        CLOSE item_check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END devide_item;
  /**********************************************************************************
   * Procedure Name   : insert_work
   * Description      : �ă��[�X�v�ۃ��[�N�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_work(
    in_file_id    IN  NUMBER,                       -- 1.�t�@�C���f�[�^
    ir_work_rtype IN  xxcff_re_lease_work%ROWTYPE,  -- 2.�ă��[�X�v�ۃ��[�N���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,              --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,              --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ă��[�X�v�ۃ��[�N�f�[�^�}������
    INSERT INTO xxcff_re_lease_work(
       object_code
      ,file_id
      ,contract_number
      ,contract_line_num
      ,re_lease_flag
      ,lease_company
      ,lease_type
      ,re_lease_times
      --WHO�J����
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       ir_work_rtype.object_code
      ,in_file_id
      ,ir_work_rtype.contract_number
      ,ir_work_rtype.contract_line_num
      ,ir_work_rtype.re_lease_flag
      ,ir_work_rtype.lease_company
      ,ir_work_rtype.lease_type
      ,ir_work_rtype.re_lease_times
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
     );
--
  EXCEPTION
--
    WHEN DUP_VAL_ON_INDEX THEN   --�����R�[�h���d���̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_dup_index_msg
                                          ,cv_not_null_tkn,     cv_tkn_val1
                                          ,cv_col_nam_tkn,      ir_work_rtype.object_code
                                          ,cv_from_info_tkn,    cv_csv_name
                  );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_work;
--
  /**********************************************************************************
   * Procedure Name   : combination_check
   * Description      : �g�ݍ��킹���݃`�F�b�N(A-6)
   ***********************************************************************************/
  PROCEDURE combination_check(
    in_file_id    IN  NUMBER,              --   1.�t�@�C��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'combination_check'; -- �v���O������
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR combi_check_cur(in_file_id NUMBER)
    IS
    SELECT
       xrlw.lease_company     lease_company
      ,xrlw.object_code       object_code
      ,xrlw.contract_number   contract_number
      ,xrlw.contract_line_num contract_line_num
      ,xrlw.re_lease_times    re_lease_times
    FROM
      xxcff_re_lease_work     xrlw
    WHERE
        xrlw.file_id          = in_file_id
    AND NOT EXISTS
      (SELECT 1
       FROM
            xxcff_contract_headers xch
           ,xxcff_contract_lines   xcl
            ,xxcff_object_headers  xoh
       WHERE
            xcl.object_header_id    = xoh.object_header_id
       AND  xch.contract_header_id  = xcl.contract_header_id
       AND  xch.re_lease_times      = xoh.re_lease_times
       AND  xch.lease_company       = xrlw.lease_company
       AND  xrlw.object_code        = xoh.object_code
       AND  xch.contract_number     = xrlw.contract_number
       AND  xcl.contract_line_num   = xrlw.contract_line_num
       AND  xch.re_lease_times      = xrlw.re_lease_times);
    -- <�J�[�\����>���R�[�h�^
    combi_check_cur_rec combi_check_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    OPEN combi_check_cur(in_file_id);
    LOOP
      FETCH combi_check_cur INTO combi_check_cur_rec;
      EXIT WHEN combi_check_cur%NOTFOUND;
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_combi_msg
                                            ,cv_combi_tkn1,      combi_check_cur_rec.object_code
                                            ,cv_combi_tkn2,      combi_check_cur_rec.contract_number
                                            ,cv_combi_tkn3,      combi_check_cur_rec.contract_line_num
                                            ,cv_combi_tkn4,      combi_check_cur_rec.lease_company
                                            ,cv_combi_tkn5,      combi_check_cur_rec.re_lease_times)
        );
      gn_error_cnt := gn_error_cnt + 1;
    END LOOP;
    CLOSE combi_check_cur;

--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF (combi_check_cur%ISOPEN) THEN
        CLOSE combi_check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END combination_check;
--
  /**********************************************************************************
   * Procedure Name   : item_validate_check
   * Description      : ���ڑÓ����`�F�b�N(A-8)
   ***********************************************************************************/
  PROCEDURE item_validate_check(
    in_code       IN  VARCHAR2,            --   1.�����R�[�h
    in_ope_date   IN  DATE,                --   2.�Ɩ����t
    in_exp_date   IN  DATE,                --   3.���[�X������
    in_flag_org   IN  VARCHAR2,            --   4.�ă��[�X�v�ی�
    in_flag       IN  VARCHAR2,            --   4.�ă��[�X�v��
    in_status_cd  IN  VARCHAR2,            --   5.�����X�e�[�^�X�R�[�h
    in_status_nm  IN  VARCHAR2,            --   6.�����X�e�[�^�X��
    on_warn_cnt   OUT NOCOPY NUMBER,       --   7.�����x�����b�Z�[�W��
    on_update_flg OUT NOCOPY NUMBER,       --   8.�X�V�Ώۃt���O 0:�X�V 1:�X�V�ΏۊO
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_validate_check'; -- �v���O������
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
    cv_re_lease_on    CONSTANT xxcff_object_headers.re_lease_flag%TYPE       := '1';   --�ă��[�X��
    cv_re_lease_off   CONSTANT xxcff_object_headers.re_lease_flag%TYPE       := '0';   --�ă��[�X�v
    cv_status_cont    CONSTANT xxcff_object_status_v.object_status_code%TYPE := '102'; --�_��
    cv_status_re_cont CONSTANT xxcff_object_status_v.object_status_code%TYPE := '104'; --�Č_��
--
    -- *** ���[�J���ϐ� ***
    ld_exp_month  DATE;  --�Ɩ���
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>

    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    on_warn_cnt   := 0;
    on_update_flg := 0;
    ld_exp_month := TRUNC(in_ope_date,'MM');

    --�������`�F�b�N
    IF (NVL(in_exp_date,ld_exp_month)  < ld_exp_month) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_exp_date_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_exp_tkn1,        in_exp_date
                                          ,cv_exp_tkn2,        in_ope_date
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --�ă��[�X�v�ۃR�[�h�`�F�b�N
    IF ( in_flag NOT IN(cv_re_lease_on, cv_re_lease_off) ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_re_lease_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_re_lease_tkn,    in_flag
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --�����X�e�[�^�X
    IF ( in_status_cd NOT IN(cv_status_cont, cv_status_re_cont) ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_obj_stat_msg
                                          ,cv_combi_tkn1,      in_code
                                          ,cv_status_tkn,      in_status_nm
                  )
      );
      on_warn_cnt := on_warn_cnt + 1;
    END IF;
    --�v�ۃt���O�l�`�F�b�N
    IF ( in_flag = in_flag_org) THEN
      on_update_flg := 1;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END item_validate_check;
--
  /**********************************************************************************
   * Procedure Name   : re_lease_update
   * Description      : �������R�[�h���b�N�ƍX�V(A-9)
   ***********************************************************************************/
  PROCEDURE re_lease_update(
    in_object_id  IN  xxcff_object_headers.object_header_id%TYPE, -- ���������h�c
    in_flag       IN  xxcff_object_headers.re_lease_flag%TYPE,    -- �ă��[�X�l
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_lease_update'; -- �v���O������
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
    ln_busy_code  NUMBER := -54;
--
    -- *** ���[�J���ϐ� ***
    ln_object_id  xxcff_object_headers.object_header_id%TYPE;
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --���[�X�������R�[�h���b�N����
    SELECT
           object_header_id AS object_header_id
    INTO
           ln_object_id
    FROM   
           xxcff_object_headers
    WHERE
           object_header_id = in_object_id
    FOR UPDATE NOWAIT;
    
    UPDATE
           xxcff_object_headers
    SET
           re_lease_flag          = in_flag
          ,last_updated_by        = cn_last_updated_by
          ,last_update_date       = cd_last_update_date
          ,last_update_login      = cn_last_update_login
          ,request_id             = cn_request_id
          ,program_application_id = cn_program_application_id
          ,program_id             = cn_program_id
          ,program_update_date    = cd_program_update_date
    WHERE  object_header_id       = in_object_id;
    
    gn_normal_cnt := gn_normal_cnt + 1;
    
--
  EXCEPTION
--
   WHEN TIMEOUT_ON_RESOURCE THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_rec_lock_msg
                                          ,cv_rec_lock_tkn,     cv_tkn_val7
                  );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      IF (SQLCODE = ln_busy_code) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_rec_lock_msg
                                            ,cv_rec_lock_tkn,     cv_tkn_val7
                    );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ELSE
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      END IF;
      ov_retcode := cv_status_error;
     --
--#####################################  �Œ蕔 END   ##########################################
--
  END re_lease_update;
--
  /**********************************************************************************
   * Procedure Name   : submain_main
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain_main(
    in_file_id    IN  NUMBER,              -- 1.�t�@�C��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain_main'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_init_rtype   xxcff_common1_pkg.init_rtype;  --���������擾���ʊi�[�p
    lr_work_rtype   xxcff_re_lease_work%ROWTYPE;   --�ă��[�X�v�ۃ��[�N���R�[�h�i�[�p
    ln_reccnt       NUMBER(10);                    --���[�v�����J�E���^
    ln_warn_cnt     NUMBER(10);                    --�Ó����`�F�b�N��������p
    ln_update_flag  NUMBER(10);                    --�X�V�Ώ۔���p
    lv_comment_flag VARCHAR2(10);                  --�o�͋敪�i�[�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR get_work_cur(in_file_id NUMBER)
    IS
    SELECT
       xoh.object_code         AS object_code
      ,xoh.expiration_date     AS expiration_date
      ,xoh.object_header_id    AS object_header_id
      ,xoh.re_lease_flag       AS re_lease_flag_org
      ,xrlw.re_lease_flag      AS re_lease_flag
      ,xoh.object_status       AS object_status
      ,xosv.object_status_name AS object_status_name
    FROM
       xxcff_object_headers    xoh
      ,xxcff_re_lease_work     xrlw
      ,xxcff_object_status_v   xosv
    WHERE
        xrlw.file_id            = in_file_id
    AND xrlw.object_code        = xoh.object_code
    AND xosv.object_status_code = xoh.object_status
    ORDER BY xoh.object_code;
    -- <�J�[�\����>���R�[�h�^
    get_work_cur_rec           get_work_cur%ROWTYPE;

--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
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
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
--
    -- ���ʏ��������̌Ăяo��
    init(
       in_file_id  => in_file_id      --   1.�t�@�C��ID
      ,or_init_rec => lr_init_rtype   --   2.�������i�[
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
    -- =====================================================
    get_if_data(
       in_file_id => in_file_id       -- 1.�t�@�C��ID
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
--
    --�z��Ɋi�[����Ă���CSV�s��1�s�Â擾����
    FOR ln_reccnt IN gr_file_data_tbl.first..gr_file_data_tbl.last LOOP
      gn_target_cnt := gn_target_cnt + 1;   --���������J�E���g
      -- =====================================================
      --  �f���~�^�������ڕ���(A-3)
      -- =====================================================
      devide_item(
         in_file_data  => gr_file_data_tbl(ln_reccnt)  -- 1.�t�@�C���f�[�^
        ,ov_flag       => lv_comment_flag              -- 2.�f�[�^�敪(�R�����g�s����p)
        ,or_work_rtype => lr_work_rtype                -- 3.�ă��[�X�v�ۃ��[�N���R�[�h
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );
      --�R�����g�s�̓X�L�b�v
      -- =====================================================
      --  �R�����g�s�`�F�b�N(A-4)
      -- =====================================================
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
      ELSIF (TRIM(lv_comment_flag) IS NULL) THEN
        gn_target_cnt := gn_target_cnt - 1;   --���������J�E���g����
      ELSE
        -- =====================================================
        --  �ă��[�X�v�ۃ��[�N�o�^(A-5)
        -- =====================================================
        IF (gn_error_cnt = 0) THEN
          insert_work(
             in_file_id    => in_file_id       -- 1.�t�@�C���f�[�^
            ,ir_work_rtype => lr_work_rtype    -- 2.�ă��[�X�v�ۃ��[�N���R�[�h
            ,ov_retcode    => lv_retcode
            ,ov_errbuf     => lv_errbuf
            ,ov_errmsg     => lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP;
--
      --�S�s�x���̏ꍇ����I��
    IF (gn_target_cnt = 0)  THEN
      return;
    END IF;
    IF (gn_error_cnt <> 0)  THEN
      --(�G���[����)
      return;
    END IF;
--
      -- =====================================================
      --  �g�ݍ��킹���݃`�F�b�N(A-6)
      -- =====================================================
    -- �K�{�`�F�b�N�A�ă��[�X�v�ۃ��[�N�o�^�ŃG���[���Ȃ���Ώ������s��
    combination_check(
       in_file_id    => in_file_id       -- 1.�t�@�C���h�c
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg
    );
    IF (gn_error_cnt<> 0) THEN
      --(�G���[����)
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    -- �g�ݍ��킹�`�F�b�N�ŃG���[������ΏI���������s��
    -- =====================================================
    --  �ă��[�X�v�ۏ�񒊏o(A-7)
    -- =====================================================
    OPEN get_work_cur(in_file_id);
    LOOP
      FETCH get_work_cur INTO get_work_cur_rec;
      EXIT WHEN get_work_cur%NOTFOUND;
      -- =====================================================
      --  ���ڑÓ����`�F�b�N(A-8)
      -- =====================================================
      item_validate_check(
         in_code       => get_work_cur_rec.object_code         -- 1.�����R�[�h
        ,in_ope_date   => lr_init_rtype.process_date           -- 2.�Ɩ����t
        ,in_exp_date   => get_work_cur_rec.expiration_date     -- 3.���[�X������
        ,in_flag_org   => get_work_cur_rec.re_lease_flag_org   -- 4.�ă��[�X�v�ی�
        ,in_flag       => get_work_cur_rec.re_lease_flag       -- 4.�ă��[�X�v��
        ,in_status_cd  => get_work_cur_rec.object_status       -- 5.�����R�X�e�[�^�X�R�[�h
        ,in_status_nm  => get_work_cur_rec.object_status_name  -- 6.�����X�e�[�^�X��
        ,on_warn_cnt   => ln_warn_cnt                          -- 7.�����x�����b�Z�[�W��
        ,on_update_flg => ln_update_flag                       -- 7.�X�V�Ώ۔���
        ,ov_retcode    => lv_retcode
        ,ov_errbuf     => lv_errbuf
        ,ov_errmsg     => lv_errmsg
      );

      IF (ln_warn_cnt <> 0) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSIF (ln_update_flag <> 0) THEN  --�X�V�s�v�̏ꍇDB�X�V�͍s�킸�A�J�E���g�A�b�v����
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- =====================================================
        --  �������R�[�h���b�N�ƍX�V(A-9)
        -- =====================================================
        re_lease_update(
           in_object_id => get_work_cur_rec.object_header_id -- 1.��������ID
          ,in_flag      => get_work_cur_rec.re_lease_flag    -- 2.�ă��[�X�v��
          ,ov_retcode   => lv_retcode
          ,ov_errbuf    => lv_errbuf
          ,ov_errmsg    => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          CLOSE get_work_cur;
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP;
    CLOSE get_work_cur;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (get_work_cur%ISOPEN) THEN
        CLOSE get_work_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_work_cur%ISOPEN) THEN
        CLOSE get_work_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain_main;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,              -- 1.�t�@�C��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- <�J�[�\����>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ===============================================
    -- submain_main�̌Ăяo���i���ۂ̏�����submain_main�ōs���j
    -- ===============================================
    submain_main(
       in_file_id  -- 1.�t�@�C��ID
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- =====================================================
    --  �I������(A-10)
    -- =====================================================
    IF (gn_error_cnt <> 0)
      OR (lv_retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      -- �ă��[�X�v�ۃ��[�N�폜
      DELETE
      FROM  xxcff_re_lease_work
      WHERE file_id = in_file_id;
    END IF;
    -- �t�@�C���A�b�v���[�hIF�e�[�u���폜
    DELETE
    FROM  xxccp_mrp_file_ul_interface
    WHERE file_id = in_file_id;
    --�ُ�I���̏ꍇ�t�@�C���A�b�v���[�hIF�e�[�u���폜�̂��߂�COMMIT���s
    IF (gn_error_cnt <> 0)
      OR (lv_retcode = cv_status_error) THEN
      COMMIT;
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT NOCOPY   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    in_file_id     IN  NUMBER,              --   1.�t�@�C��ID
    iv_file_format IN  VARCHAR2             --   2.�t�@�C���t�H�[�}�b�g
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
      ,iv_which   => cv_out
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
       in_file_id  -- 1.�t�@�C��ID
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
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
END XXCFF004A10C;
/
