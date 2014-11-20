CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A03C(body)
 * Description      : ���σw�b�_�A���ϖ��׃f�[�^�����n�V�X�e���ɑ��M���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_016_A03_���n-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)���Ϗ��f�[�^
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  set_param_default      �p�����[�^�f�t�H���g�Z�b�g(A-2)
 *  chk_param              �p�����[�^�`�F�b�N(A-3)
 *  get_profile_info       �v���t�@�C���l�擾(A-4)
 *  open_csv_file_header   ���σw�b�_���CSV�t�@�C���I�[�v��(A-5)
 *  open_csv_file_lines    ���ϖ��׏��CSV�t�@�C���I�[�v��(A-6)
 *  get_xqh_data_for_sale  �̔���p���σw�b�_�[���o(A-8)
 *  get_hcsu_data          �ڋq�g�p�ړI�}�X�^���o(A-9)
 *  create_csv_rec_lines   ���ϖ��׏��CSV�o��(A-11)
 *  create_csv_rec_header  ���σw�b�_�[���CSV�o��(A-12)
 *  close_csv_file_lines   ���ϖ��׏��CSV�t�@�C���N���[�Y����(A-13)
 *  close_csv_file_header  ���σw�b�_���CSV�t�@�C���N���[�Y����(A-14)
 *  submain                ���C�������v���V�[�W��
 *                           ���σw�b�_��񒊏o����(A-7)
 *                           ���ϖ��׏�񒊏o����(A-10)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-15)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-02-25    1.1   K.Sai            ���r���[���ʔ��f 
 *  2009-04-16    1.2   K.Satomura       �V�X�e���e�X�g��Q�Ή�(T1_0172,T1_0508)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2010-01-08    1.4   Kazuyo.Hosoi     E_�{�ғ�_01017�Ή�
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A03C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00145';  -- �p�����[�^�X�V�� FROM
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00146';  -- �p�����[�^�X�V�� TO
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';  -- �p�����[�^�f�t�H���g�Z�b�g
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00384';  -- ���t�����G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00013';  -- �p�����[�^�������G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';  -- �f�[�^���o�G���[
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00151';  -- �f�[�^���o�x�����b�Z�[�W
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00225';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W(���ϖ���)
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00020';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W(���σw�b�_���)
  -- �g�[�N���R�[�h
  cv_tkn_frm_val           CONSTANT VARCHAR2(20) := 'FROM_VALUE';
  cv_tkn_to_val            CONSTANT VARCHAR2(20) := 'TO_VALUE';
  cv_tkn_val               CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status            CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_csv_fnm           CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prof_nm           CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc           CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_errmsg            CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage        CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prcss_nm          CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_estmt_no          CONSTANT VARCHAR2(20) := 'ESTIMATE_NO';
  cv_tkn_estmt_type        CONSTANT VARCHAR2(20) := 'ESTIMATE_TYPE';
  cv_tkn_estmt_edtn        CONSTANT VARCHAR2(20) := 'ESTIMATE_EDITION';
  cv_tkn_dtl_id            CONSTANT VARCHAR2(20) := 'DETAILE_ID';
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm_hdr = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := 'lv_csv_nm_lns = ';
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg12         CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg13         CONSTANT VARCHAR2(200) := '<< �N���p�����[�^ >>';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '�X�V��FROM : ';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '�X�V��TO : ';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := 'lv_org_id = ';
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls3     CONSTANT VARCHAR2(200) := '<< ��O�������Ō��σw�b�_���擾�J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls4     CONSTANT VARCHAR2(200) := '<< ��O�������Ō��ϖ��׏��擾�J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_skip      CONSTANT VARCHAR2(200) := '<< �̔���p�ڋq�R�[�h�擾���s�̂��߃X�L�b�v���܂��� >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'others��O';
--
  cv_w                   CONSTANT VARCHAR2(1)   := 'w';  -- CSV�t�@�C���I�[�v�����[�h
  cv_status_fix          CONSTANT VARCHAR2(1)   := '2';  -- �X�e�[�^�X(2:�m��)
  cv_quote_type1         CONSTANT VARCHAR2(1)   := '1';  -- ���ώ��(1:�̔���p)
  cv_quote_type2         CONSTANT VARCHAR2(1)   := '2';  -- ���ώ��(2:�����≮��p)
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand_header    UTL_FILE.FILE_TYPE;       -- ���σw�b�_�p
  gf_file_hand_lines     UTL_FILE.FILE_TYPE;       -- ���ϖ��חp
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`(���σw�b�_�[���)
  TYPE g_get_data_hdr_rtype IS RECORD(
     company_cd              VARCHAR2(3)                                       -- ��ЃR�[�h
    ,quote_number            xxcso_quote_headers.quote_number%TYPE             -- ���Ϗ��ԍ�
    ,reference_quote_number  xxcso_quote_headers.reference_quote_number%TYPE   -- �Q�ƌ��Ϗ��ԍ�
    ,quote_revision_number   xxcso_quote_headers.quote_revision_number%TYPE    -- �Ő�
    ,quote_type              xxcso_quote_headers.quote_type%TYPE               -- ���ώ��
    ,account_number_for_sale xxcso_quote_headers.account_number%TYPE           -- �̔���ڋq�ԍ�
    ,account_number          xxcso_quote_headers.account_number%TYPE           -- �ڋq�R�[�h
    ,publish_date            xxcso_quote_headers.publish_date%TYPE             -- ���s��
    ,employee_number         xxcso_quote_headers.employee_number%TYPE          -- �S���҃R�[�h
    /* 2009.04.16 K.Satomura T1_0172�Ή� START */
    --,deliv_place             xxcso_quote_headers.deliv_place%TYPE              -- �[���ꏊ
    ,deliv_place             VARCHAR2(60)                                      -- �[���ꏊ
    /* 2009.04.16 K.Satomura T1_0172�Ή� END */
    ,name                    ra_terms_vl.name%TYPE                             -- �x������
    ,quote_info_start_date   xxcso_quote_headers.quote_info_start_date%TYPE    -- ���Ϗ�����(��)
    ,quote_info_end_date     xxcso_quote_headers.quote_info_end_date%TYPE      -- ���Ϗ�����(��)
    /* 2009.04.16 K.Satomura T1_0172�Ή� START */
    --,quote_submit_name       xxcso_quote_headers.quote_submit_name%TYPE        -- ���Ϗ���o�於��
    --,special_note            xxcso_quote_headers.special_note%TYPE             -- ���L����
    ,quote_submit_name       VARCHAR2(40)                                      -- ���Ϗ���o�於��
    ,special_note            VARCHAR2(100)                                     -- ���L����
    /* 2009.04.16 K.Satomura T1_0172�Ή� END */
    ,status                  xxcso_quote_headers.status%TYPE                   -- �X�e�[�^�X
    ,deliv_price_tax_type    xxcso_quote_headers.deliv_price_tax_type%TYPE     -- �X�[���i�ŋ敪
    ,unit_type               xxcso_quote_headers.unit_type%TYPE                -- �P���敪
    ,cprtn_date              DATE                                              -- �A�g����
  );
  -- CSV�o�̓f�[�^�i�[�p���R�[�h�^��`(���ϖ��׏��)
  TYPE g_get_data_lns_rtype IS RECORD(
     company_cd                 VARCHAR2(3)                                        -- ��ЃR�[�h
    ,quote_line_id              xxcso_quote_lines.quote_line_id%TYPE               -- ����ID
    ,quote_number               xxcso_quote_headers.quote_number%TYPE              -- ���Ϗ��ԍ�
    ,inventory_item_code        mtl_system_items_b.segment1%TYPE                   -- ���i�R�[�h
    ,quote_div                  xxcso_quote_lines.quote_div%TYPE                   -- ���ϋ敪
    ,usually_deliv_price        xxcso_quote_lines.usually_deliv_price%TYPE         -- �ʏ�X�[���i
    ,this_time_deliv_price      xxcso_quote_lines.this_time_deliv_price%TYPE       -- ����X�[���i
    ,usually_store_sale_price   xxcso_quote_lines.usually_store_sale_price%TYPE    -- �ʏ�X�����i
    ,quotation_price            xxcso_quote_lines.quotation_price%TYPE             -- ���l
    ,this_time_store_sale_price xxcso_quote_lines.this_time_store_sale_price%TYPE  -- ����X�����i
    ,this_time_net_price        xxcso_quote_lines.this_time_net_price%TYPE         -- ����NET���i
    ,amount_of_margin           xxcso_quote_lines.amount_of_margin%TYPE            -- �}�[�W���z
    ,margin_rate                xxcso_quote_lines.margin_rate%TYPE                 -- �}�[�W����
    ,sales_discount_price       xxcso_quote_lines.sales_discount_price%TYPE        -- �l��
    ,business_price             xxcso_quote_lines.business_price%TYPE              -- �c�ƌ���
    ,quote_start_date           xxcso_quote_lines.quote_start_date%TYPE            -- �L������(��)
    ,quote_end_date             xxcso_quote_lines.quote_end_date%TYPE              -- �L������(��)
    /* 2009.04.16 K.Satomura T1_0172�Ή� START */
    --,remarks                    xxcso_quote_lines.remarks%TYPE                     -- ���l
    ,remarks                    VARCHAR2(20)                                       -- ���l
    /* 2009.04.16 K.Satomura T1_0172�Ή� END */
    ,line_order                 xxcso_quote_lines.line_order%TYPE                  -- ���я�
    ,usuall_net_price           xxcso_quote_lines.usuall_net_price%TYPE            -- �ʏ�NET���i
    ,cprtn_date                 DATE                                               -- �A�g����
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_from_value       IN  VARCHAR2         --   �p�����[�^�X�V�� FROM
    ,iv_to_value         IN  VARCHAR2         --   �p�����[�^�X�V�� TO
    ,od_sysdate          OUT DATE             -- �V�X�e�����t
    ,od_process_date     OUT DATE             -- �Ɩ��������t
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_from         VARCHAR2(5000);
    lv_msg_to           VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02      --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_frm_val        --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_from_value         --�g�[�N���l1
                   );
    lv_msg_to := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_03      --���b�Z�[�W�R�[�h
                  ,iv_token_name1  => cv_tkn_to_val         --�g�[�N���R�[�h1
                  ,iv_token_value1 => iv_to_value           --�g�[�N���l1
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_from
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_to
    );
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (od_process_date IS NULL) THEN
      -- ��s�̑}��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
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
   * Procedure Name   : set_param_default
   * Description      : �p�����[�^�f�t�H���g�Z�b�g(A-2)
   ***********************************************************************************/
  PROCEDURE set_param_default(
     id_process_date     IN DATE                 -- �Ɩ��������t  
    ,io_from_value       IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_param_default';  -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_set_param    VARCHAR2(5000);
    -- �N���p�����[�^�f�t�H���g�Z�b�g�t���O
    lb_set_param_flg BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �N���p�����[�^NULL�`�F�b�N
    -- ===========================
    -- �X�V��FROM ��NULL�̏ꍇ
    IF (io_from_value IS NULL) THEN
      -- �X�V��FROM �ɋƖ��������t���Z�b�g
      io_from_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
    -- �X�V��TO ��NULL�̏ꍇ
    IF (io_to_value IS NULL) THEN
      -- �X�V��TO �ɋƖ��������t���Z�b�g
      io_to_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
--
    IF (lb_set_param_flg = cb_true) THEN
      -- ==========================================
      -- �p�����[�^�f�t�H���g�Z�b�g���b�Z�[�W�o��
      -- ==========================================
      lv_msg_set_param := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_04      --���b�Z�[�W�R�[�h
                          );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg_set_param
      );
    END IF;
--
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- *** DEBUG_LOG ***
    -- �p�����[�^�f�t�H���g�Z�b�g��̋N���p�����[�^�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg13 || CHR(10) ||
                 cv_debug_msg14 || io_from_value || CHR(10) ||
                 cv_debug_msg15 || io_to_value   || CHR(10) ||
                 ''
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
  END set_param_default;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_param(
     io_from_value       IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- �p�����[�^�X�V�� TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';     -- �v���O������
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
    cv_date_format CONSTANT VARCHAR2(8) := 'YYYYMMDD';
    cv_false       CONSTANT VARCHAR2(5) := 'FALSE';
    -- *** ���[�J���ϐ� ***
    -- �p�����[�^�`�F�b�N�߂�l�i�[�p
    lb_chk_date_from BOOLEAN DEFAULT TRUE;
    lb_chk_date_to   BOOLEAN DEFAULT TRUE;
    -- *** ���[�J����O ***
    chk_param_expt   EXCEPTION;  -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- ���t�����`�F�b�N
    -- ===========================
    lb_chk_date_from := xxcso_util_common_pkg.check_date(
                          iv_date         => io_from_value
                         ,iv_date_format  => cv_date_format
                        );
    lb_chk_date_to := xxcso_util_common_pkg.check_date(
                        iv_date         => io_to_value
                       ,iv_date_format  => cv_date_format
                      );
--
    -- �p�����[�^�X�V�� FROM �̓��t������'YYYYMMDD'�`���łȂ��ꍇ
    IF (lb_chk_date_from = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_val                   --�g�[�N���R�[�h1
                    ,iv_token_value1 => io_from_value                --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_status                --�g�[�N���R�[�h2
                    ,iv_token_value2 => cv_false                     --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    -- �p�����[�^�X�V�� TO �̓��t������'YYYYMMDD'�`���łȂ��ꍇ
    ELSIF (lb_chk_date_to = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_05             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_val                   --�g�[�N���R�[�h1
                    ,iv_token_value1 => io_to_value                  --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_status                --�g�[�N���R�[�h2
                    ,iv_token_value2 => cv_false                     --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- ���t�召�֌W�`�F�b�N
    -- ===========================
    IF (TO_DATE(io_from_value,'yyyymmdd') > TO_DATE(io_to_value,'yyyymmdd')) THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_frm_val               --�g�[�N���R�[�h1
                       ,iv_token_value1 => io_from_value                --�g�[�N���l1
                       ,iv_token_name2  => cv_tkn_to_val                --�g�[�N���R�[�h2
                       ,iv_token_value2 => io_to_value                  --�g�[�N���l2
                      );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N��O ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- ��ЃR�[�h�i�Œ�l001�j
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSV�t�@�C���o�͐�
    ,ov_csv_nm_hdr     OUT NOCOPY VARCHAR2  -- CSV�t�@�C����(���σw�b�_)
    ,ov_csv_nm_lns     OUT NOCOPY VARCHAR2  -- CSV�t�@�C����(���ϖ���)
    ,ov_org_id         OUT NOCOPY VARCHAR2  -- ORG_ID
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_info';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################

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
    -- �v���t�@�C����
    -- XXCSO:���n�A�g�p��ЃR�[�h
    cv_prfnm_cmp_cd          CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:���n�A�g�pCSV�t�@�C���o�͐�
    cv_prfnm_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:���n�A�g�pCSV�t�@�C����(���σw�b�_)
    cv_prfnm_csv_estmt_hdr   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_ESTMT_HDR';
    -- XXCSO:���n�A�g�pCSV�t�@�C����(���ϖ���)
    cv_prfnm_csv_estmt_lns   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_ESTMT_LNS';
    -- OE:�i�ڌ��ؑg�D
    cv_prfnm_org_id          CONSTANT VARCHAR2(30)   := 'SO_ORGANIZATION_ID';
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_company_cd               VARCHAR2(2000);      -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_dir                  VARCHAR2(2000);      -- CSV�t�@�C���o�͐�
    lv_csv_nm_hdr               VARCHAR2(2000);      -- CSV�t�@�C����(���σw�b�_)
    lv_csv_nm_lns               VARCHAR2(2000);      -- CSV�t�@�C����(���ϖ���)
    lv_org_id                   VARCHAR2(2000);      -- �I���OID
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg_hdr                  VARCHAR2(5000);
    lv_msg_lns                  VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �ϐ����������� 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- ��ЃR�[�h�i�Œ�l001�j
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSV�t�@�C���o�͐�
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_estmt_hdr
                   ,val  => lv_csv_nm_hdr
                   ); -- CSV�t�@�C����(���σw�b�_)
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_estmt_lns
                   ,val  => lv_csv_nm_lns
                   ); -- CSV�t�@�C����(���ϖ���)
    FND_PROFILE.GET(
                    name => cv_prfnm_org_id
                   ,val  => lv_org_id
                   ); -- �I���OID
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm_hdr || CHR(10) ||
                 cv_debug_msg9  || lv_csv_nm_lns || CHR(10) ||
                 cv_debug_msg16 || lv_org_id     || CHR(10) ||
                 ''
    );
--
    -- �擾����CSV�t�@�C���������b�Z�[�W�o�͂���
    -- CSV�t�@�C����(���σw�b�_)
    lv_msg_hdr := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_07      --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_csv_fnm        --�g�[�N���R�[�h1
                   ,iv_token_value1 => lv_csv_nm_hdr         --�g�[�N���l1
                  );
    -- CSV�t�@�C����(���ϖ���)
    lv_msg_lns := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_07      --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_csv_fnm        --�g�[�N���R�[�h1
                   ,iv_token_value1 => lv_csv_nm_lns         --�g�[�N���l1
                  );
--
    --���b�Z�[�W�o��(���σw�b�_)
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_hdr
    );
    --���b�Z�[�W�o��(���ϖ���)
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_lns
    );
--
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- ��ЃR�[�h�擾���s��
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSV�t�@�C���o�͐�擾���s��
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSV�t�@�C�����擾���s��
    ELSIF (lv_csv_nm_hdr IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_estmt_hdr;
    ELSIF (lv_csv_nm_lns IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_estmt_lns;
    ELSIF (lv_org_id IS NULL) THEN
      lv_tkn_value := cv_prfnm_org_id;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_08             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_company_cd     :=  lv_company_cd;       -- ��ЃR�[�h�i�Œ�l001�j
    ov_csv_dir        :=  lv_csv_dir;          -- CSV�t�@�C���o�͐�
    ov_csv_nm_hdr     :=  lv_csv_nm_hdr;       -- CSV�t�@�C����(���σw�b�_)
    ov_csv_nm_lns     :=  lv_csv_nm_lns;       -- CSV�t�@�C����(���ϖ���)
    ov_org_id         :=  lv_org_id;           -- �I���OID
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file_header
   * Description      : ���σw�b�_���CSV�t�@�C���I�[�v��(A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file_header(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file_header';  -- �v���O������
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
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
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
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand_header := UTL_FILE.FOPEN(
                               location   => iv_csv_dir
                              ,filename   => iv_csv_nm
                              ,open_mode  => cv_w
                             );
    -- *** DEBUG_LOG ***
    -- �t�@�C���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_10     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END open_csv_file_header;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file_lines
   * Description      : ���ϖ��׏��CSV�t�@�C���I�[�v��(A-6)
   ***********************************************************************************/
  PROCEDURE open_csv_file_lines(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file_lines';  -- �v���O������
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
    -- �t�@�C�����݃`�F�b�N�߂�l�p
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
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
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- ���łɃt�@�C�������݂����ꍇ
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_09             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                    ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSV�t�@�C���I�[�v�� 
    -- ========================
    BEGIN
      -- �t�@�C���I�[�v��
      gf_file_hand_lines  := UTL_FILE.FOPEN(
                               location   => iv_csv_dir
                              ,filename   => iv_csv_nm
                              ,open_mode  => cv_w
                             );
    -- *** DEBUG_LOG ***
    -- �t�@�C���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_10     --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc       --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir           --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm            --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END open_csv_file_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_xqh_data_for_sale
   * Description      : �̔���p���σw�b�_�[���o(A-8)
   ***********************************************************************************/
  PROCEDURE get_xqh_data_for_sale(
     io_hdr_data_rec    IN OUT NOCOPY g_get_data_hdr_rtype -- ���σw�b�_�f�[�^
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xqh_data_for_sale';  -- �v���O������
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
    cv_prcss_nm   CONSTANT VARCHAR2(100) := '�̔���p���σw�b�_�[';
    -- *** ���[�J���ϐ� ***
    --�擾�f�[�^�i�[�p
    lt_accnt_num_for_sl  xxcso_quote_headers.account_number%TYPE;    -- �̔���p�ڋq�R�[�h
    -- *** ���[�J����O ***
    no_data_expt         EXCEPTION;                                  -- �Ώۃf�[�^0����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================
    -- �̔���p���σw�b�_�[���o
    -- ============================
    BEGIN
      SELECT xqh.account_number    account_number       -- �̔���p�ڋq�R�[�h
      INTO   lt_accnt_num_for_sl
      FROM   xxcso_quote_headers  xqh                   -- ���σw�b�_�[�e�[�u��
      WHERE  xqh.quote_type   = cv_quote_type1
      AND    xqh.quote_number = io_hdr_data_rec.reference_quote_number
      AND    xqh.status       = cv_status_fix
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �x�����b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_13                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_estmt_no                        --�g�[�N���R�[�h2
                      ,iv_token_value2 => io_hdr_data_rec.quote_number           --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_estmt_type                      --�g�[�N���R�[�h3
                      ,iv_token_value3 => io_hdr_data_rec.quote_type             --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_estmt_edtn                      --�g�[�N���R�[�h4
                      ,iv_token_value4 => io_hdr_data_rec.quote_revision_number  --�g�[�N���l4
                      ,iv_token_name5  => cv_tkn_errmsg                          --�g�[�N���R�[�h4
                      ,iv_token_value5 => SQLERRM                                --�g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
--
        RAISE no_data_expt;
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage                      --�g�[�N���R�[�h4
                      ,iv_token_value2 => SQLERRM                                --�g�[�N���l4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    io_hdr_data_rec.account_number_for_sale := lt_accnt_num_for_sl;              -- �̔���p�ڋq�R�[�h
--
  EXCEPTION
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_xqh_data_for_sale;
--
  /**********************************************************************************
   * Procedure Name   : get_hcsu_data
   * Description      : �ڋq�g�p�ړI�}�X�^���o(A-9)
   ***********************************************************************************/
  PROCEDURE get_hcsu_data(
     id_process_date    IN     DATE                        -- �Ɩ��������t  
    ,io_hdr_data_rec    IN OUT NOCOPY g_get_data_hdr_rtype -- ���σw�b�_�f�[�^
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hcsu_data';  -- �v���O������
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
    cv_duns_num_c_30  CONSTANT VARCHAR2(2)   := '30';       -- ���F�ς�
    cv_duns_num_c_40  CONSTANT VARCHAR2(2)   := '40';       -- �ڋq
    cv_duns_num_c_50  CONSTANT VARCHAR2(2)   := '50';       -- �x�~
    cv_site_use_code  CONSTANT VARCHAR2(10)  := 'BILL_TO';  -- ������
    cv_prcss_nm       CONSTANT VARCHAR2(100) := '�ڋq�}�X�^�E�ڋq�A�h�I���}�X�^';
    /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� START */
    cv_active         CONSTANT VARCHAR2(1)   := 'A';        -- �ڋq�g�p�ړI�}�X�^ �X�e�[�^�X
    /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� END */
    -- *** ���[�J���ϐ� ***
    --�擾�f�[�^�i�[�p
    lt_name           ra_terms_vl.name%TYPE;    -- �x������
    ld_process_date   DATE;                     -- �ҏW�� �Ɩ��������t �i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ��������t���i�[
    ld_process_date := TRUNC(id_process_date);
--
    -- ============================
    -- �ڋq�g�p�ړI�}�X�^���o
    -- ============================
    BEGIN
      SELECT rtv.name                            -- �x������
      INTO   lt_name
      FROM   hz_cust_accounts   hca              -- �ڋq�}�X�^
            ,hz_cust_acct_sites hcas             -- �ڋq���ݒn�}�X�^VIEW
            ,hz_cust_site_uses  hcsu             -- �ڋq�g�p�ړI�}�X�^VIEW
            ,ra_terms_vl        rtv              -- �x�������}�X�^VIEW
            ,hz_parties         hp               -- �p�[�e�B�T�C�g
      WHERE hca.account_number             = io_hdr_data_rec.account_number
        AND hp.duns_number_c IN (cv_duns_num_c_30,cv_duns_num_c_40,cv_duns_num_c_50)
        AND hca.cust_account_id            =  hcas.cust_account_id
        AND hcas.cust_acct_site_id         =  hcsu.cust_acct_site_id
        AND hcsu.site_use_code             =  cv_site_use_code
        AND hcsu.payment_term_id           =  rtv.term_id
        /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� START */
        AND hcsu.status                    =  cv_active
        /* 2010.01.08 K.Hosoi E_�{�ғ�_01017�Ή� END */
        AND rtv.start_date_active          <= ld_process_date
        AND NVL(rtv.end_date_active,ld_process_date)
              >=  ld_process_date
        AND hp.party_id                    =  hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �f�[�^�����݂��Ȃ��ꍇ��NULL��ݒ�
      lt_name := NULL;
      WHEN TOO_MANY_ROWS THEN
      -- �f�[�^��������ꂽ�ꍇ��NULL��ݒ�
      lt_name := NULL;
      -- OTHERS��O�n���h�� 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_11                       --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_prcss_nm                            --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage                      --�g�[�N���R�[�h4
                      ,iv_token_value2 => SQLERRM                                --�g�[�N���l4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    io_hdr_data_rec.name := lt_name;              -- �x������
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
  END get_hcsu_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec_lines
   * Description      : ���ϖ��׏��CSV�o��(A-11)
   ***********************************************************************************/
  PROCEDURE create_csv_rec_lines(
     i_lns_data_rec      IN  g_get_data_lns_rtype    -- ���ϖ��׏��f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec_lines';     -- �v���O������
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data            VARCHAR2(5000);       -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_lns_data_rec     g_get_data_lns_rtype; -- IN�p�����[�^.���ϖ��׏��f�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;          -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_lns_data_rec := i_lns_data_rec;       -- ���ϖ��׏��f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot || l_lns_data_rec.company_cd || cv_sep_wquot                     -- ��ЃR�[�h
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_line_id)                                 -- ����ID
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.quote_number           || cv_sep_wquot -- ���Ϗ��ԍ�
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.inventory_item_code    || cv_sep_wquot -- ���i�R�[�h
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.quote_div              || cv_sep_wquot -- ���ϋ敪
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usually_deliv_price, 0))                   -- �ʏ�X�[���i
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_deliv_price, 0))                 -- ����X�[���i
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usually_store_sale_price, 0))              -- �ʏ�X�����i
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.quotation_price, 0))                       -- ���l
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_store_sale_price, 0))            -- ����X�����i
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_net_price, 0))                   -- ����NET���i
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.amount_of_margin, 0))                      -- �}�[�W���z
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.margin_rate, 0))                           -- �}�[�W����
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.sales_discount_price, 0))                  -- �l��
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.business_price, 0))                        -- �c�ƌ���
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_start_date, 'yyyymmdd')                  -- �L������(��)
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_end_date, 'yyyymmdd')                    -- �L������(��)
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.remarks  || cv_sep_wquot               -- ���l
        || cv_sep_com || TO_CHAR(l_lns_data_rec.line_order)                                    -- ���я�
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usuall_net_price, 0))                      -- �ʏ�NET���i
        || cv_sep_com || TO_CHAR(l_lns_data_rec.cprtn_date, 'yyyymmddhh24miss')                -- �A�g����
      ;
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand_lines
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_14                         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_dtl_id                            --�g�[�N���R�[�h1
                      ,iv_token_value1 => TO_CHAR(l_lns_data_rec.quote_line_id)    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_estmt_no                          --�g�[�N���R�[�h2
                      ,iv_token_value2 => l_lns_data_rec.quote_number              --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_errmsg                            --�g�[�N���R�[�h3
                      ,iv_token_value3 => SQLERRM                                  --�g�[�N���l3
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END create_csv_rec_lines;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec_header
   * Description      : ���σw�b�_�[���CSV�o��(A-12)
   ***********************************************************************************/
  PROCEDURE create_csv_rec_header(
     i_hdr_data_rec      IN  g_get_data_hdr_rtype    -- ���σw�b�_�[���f�[�^
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec_header';     -- �v���O������
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lv_data            VARCHAR2(5000);       -- �ҏW�f�[�^�i�[
--
    -- *** ���[�J���E���R�[�h ***
    l_hdr_data_rec     g_get_data_hdr_rtype; -- IN�p�����[�^.���σw�b�_�[���f�[�^�i�[
    -- *** ���[�J����O ***
    file_put_line_expt   EXCEPTION;          -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����R�[�h�ϐ��Ɋi�[
    l_hdr_data_rec := i_hdr_data_rec;       -- ���ϖ��׏��f�[�^
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- �f�[�^�쐬
      lv_data := cv_sep_wquot || l_hdr_data_rec.company_cd || cv_sep_wquot                     -- ��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_number           || cv_sep_wquot -- ���Ϗ��ԍ�
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.reference_quote_number || cv_sep_wquot -- �Q�ƌ��Ϗ��ԍ�
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_revision_number)                         -- �Ő�
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_type             || cv_sep_wquot -- ���ώ��
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.account_number_for_sale|| cv_sep_wquot -- �̔���ڋq�ԍ�
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.account_number         || cv_sep_wquot -- �ڋq�R�[�h
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.publish_date,'yyyymmdd')                       -- ���s��
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.employee_number        || cv_sep_wquot -- �S���҃R�[�h
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.deliv_place            || cv_sep_wquot -- �[���ꏊ
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.name                   || cv_sep_wquot -- �x������
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_info_start_date,'yyyymmdd')              -- ���Ϗ�����(��)
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_info_end_date,'yyyymmdd')                -- ���Ϗ�����(��)
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_submit_name      || cv_sep_wquot -- ���Ϗ���o�於��
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.special_note           || cv_sep_wquot -- ���L����
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.status                 || cv_sep_wquot -- �X�e�[�^�X
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.deliv_price_tax_type   || cv_sep_wquot -- �X�[���i�ŋ敪
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.unit_type              || cv_sep_wquot -- �P���敪
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.cprtn_date, 'yyyymmddhh24miss')                -- �A�g����
      ;
--
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand_header
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_15                         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_estmt_no                          --�g�[�N���R�[�h1
                      ,iv_token_value1 => l_hdr_data_rec.quote_number              --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_estmt_type                        --�g�[�N���R�[�h2
                      ,iv_token_value2 => l_hdr_data_rec.quote_type                --�g�[�N���l2
                      ,iv_token_name3  => cv_tkn_estmt_edtn                        --�g�[�N���R�[�h3
                      ,iv_token_value3 => l_hdr_data_rec.quote_revision_number     --�g�[�N���l3
                      ,iv_token_name4  => cv_tkn_errmsg                            --�g�[�N���R�[�h3
                      ,iv_token_value4 => SQLERRM                                  --�g�[�N���l3
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END create_csv_rec_header;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file_lines
   * Description      : ���ϖ��׏��CSV�t�@�C���N���[�Y����(A-13)
   ***********************************************************************************/
  PROCEDURE close_csv_file_lines(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file_lines';  -- �v���O������
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
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand_lines
      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END close_csv_file_lines;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file_header
   * Description      : ���σw�b�_���CSV�t�@�C���N���[�Y����(A-14)
   ***********************************************************************************/
  PROCEDURE close_csv_file_header(
     iv_csv_dir        IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_csv_nm         IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file_header';  -- �v���O������
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
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand_header
      );
    -- *** DEBUG_LOG ***
    -- �t�@�C���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_loc               --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_csv_dir                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --�g�[�N���R�[�h2
                      ,iv_token_value2 => iv_csv_nm                    --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END close_csv_file_header;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_from_value       IN  VARCHAR2          -- �p�����[�^�X�V�� FROM
    ,iv_to_value         IN  VARCHAR2          -- �p�����[�^�X�V�� TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    lv_from_value   VARCHAR2(2000); -- �p�����[�^�X�V�� FROM
    lv_to_value     VARCHAR2(2000); -- �p�����[�^�X�V�� TO
    ld_from_value   DATE;           -- �ҏW��p�����[�^�X�V�� FROM �i�[�p
    ld_to_value     DATE;           -- �ҏW��p�����[�^�X�V�� TO   �i�[�p
    ld_sysdate      DATE;           -- �V�X�e�����t
    ld_process_date DATE;           -- �Ɩ��������t
    lv_company_cd   VARCHAR2(2000); -- ��ЃR�[�h�i�Œ�l001�j
    lv_csv_dir      VARCHAR2(2000); -- CSV�t�@�C���o�͐�
    lv_csv_nm_hdr   VARCHAR2(2000); -- CSV�t�@�C����(���σw�b�_)
    lv_csv_nm_lns   VARCHAR2(2000); -- CSV�t�@�C����(���ϖ���)
    lv_org_id       VARCHAR2(2000); -- ORG_ID
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd_hdr   BOOLEAN;
    lb_fopn_retcd_lns   BOOLEAN;
    --
    lt_quote_header_id xxcso_quote_headers.quote_header_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���σw�b�_��񒊏o�J�[�\��
    CURSOR get_headers_data_cur
    IS
      /* 2009.04.16 K.Satomura T1_0172,T1_0508�Ή� START */
      --SELECT   xqh.quote_header_id          quote_header_id         -- ���σw�b�_�[ID
      --        ,xqh.quote_number             quote_number            -- ���Ϗ��ԍ�
      --        ,xqh.reference_quote_number   reference_quote_number  -- �Q�ƌ��Ϗ��ԍ�
      --        ,xqh.quote_revision_number    quote_revision_number   -- ��
      --        ,xqh.quote_type               quote_type              -- ���ώ��
      --        ,xqh.account_number           account_number          -- �ڋq�R�[�h
      --        ,xqh.publish_date             publish_date            -- ���s��
      --        ,xqh.employee_number          employee_number         -- �S���҃R�[�h
      --        ,xqh.deliv_place              deliv_place             -- �[���ꏊ
      --        ,xqh.quote_info_start_date    quote_info_start_date   -- ���Ϗ�����(��)
      --        ,xqh.quote_info_end_date      quote_info_end_date     -- ���Ϗ�����(��)
      --        ,xqh.quote_submit_name        quote_submit_name       -- ���Ϗ���o�於��
      --        ,xqh.special_note             special_note            -- ���L����
      --        ,xqh.status                   status                  -- �X�e�[�^�X
      --        ,xqh.deliv_price_tax_type     deliv_price_tax_type    -- �X�[���i�ŋ敪
      --        ,xqh.unit_type                unit_type               -- �P���敪
      SELECT TRANSLATE(xqh.quote_header_id, CHR(10) || CHR(13), '  ')        quote_header_id        -- ���σw�b�_�[ID
            ,TRANSLATE(xqh.quote_number, CHR(10) || CHR(13), '  ')           quote_number           -- ���Ϗ��ԍ�
            ,TRANSLATE(xqh.reference_quote_number, CHR(10) || CHR(13), '  ') reference_quote_number -- �Q�ƌ��Ϗ��ԍ�
            ,TRANSLATE(xqh.quote_revision_number, CHR(10) || CHR(13), '  ')  quote_revision_number  -- ��
            ,TRANSLATE(xqh.quote_type, CHR(10) || CHR(13), '  ')             quote_type             -- ���ώ��
            ,TRANSLATE(xqh.account_number, CHR(10) || CHR(13), '  ')         account_number         -- �ڋq�R�[�h
            ,TRANSLATE(xqh.publish_date, CHR(10) || CHR(13), '  ')           publish_date           -- ���s��
            ,TRANSLATE(xqh.employee_number, CHR(10) || CHR(13), '  ')        employee_number        -- �S���҃R�[�h
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.deliv_place, CHR(10) || CHR(13), '  ')),1, 60)      deliv_place            -- �[���ꏊ
            ,TRANSLATE(xqh.quote_info_start_date, CHR(10) || CHR(13), '  ')  quote_info_start_date  -- ���Ϗ�����(��)
            ,TRANSLATE(xqh.quote_info_end_date, CHR(10) || CHR(13), '  ')    quote_info_end_date    -- ���Ϗ�����(��)
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.quote_submit_name, CHR(10) || CHR(13), '  ')), 1, 40) quote_submit_name    -- ���Ϗ���o�於��
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.special_note ,CHR(10) || CHR(13), '  ')), 1, 100)   special_note           -- ���L����
            ,TRANSLATE(xqh.status, CHR(10) || CHR(13), '  ')                 status                 -- �X�e�[�^�X
            ,TRANSLATE(xqh.deliv_price_tax_type, CHR(10) || CHR(13), '  ')   deliv_price_tax_type   -- �X�[���i�ŋ敪
            ,TRANSLATE(xqh.unit_type, CHR(10) || CHR(13), '  ')              unit_type              -- �P���敪
      /* 2009.04.16 K.Satomura T1_0172,T1_0508�Ή� END */
      FROM  xxcso_quote_headers  xqh      -- ���σw�b�_�[�e�[�u��
      WHERE (TRUNC(xqh.last_update_date)
              BETWEEN ld_from_value AND ld_to_value
             )
        AND xqh.status = cv_status_fix
    ;
--
    -- ���ϖ��׏�񒊏o�J�[�\��
    CURSOR get_lines_data_cur(
             it_qt_hdr_id IN xxcso_quote_headers.quote_header_id%TYPE  -- ���σw�b�_�[ID
           )
    IS
      /* 2009.04.16 K.Satomura T1_0172,T1_0508�Ή� START */
      --SELECT xql.quote_line_id                quote_line_id                -- ����ID
      --       ,xrh.quote_number                quote_number                 -- ���Ϗ��ԍ�
      --       ,msib.segment1                   inventory_item_code          -- ���i�R�[�h
      --       ,xql.quote_div                   quote_div                    -- ���ϋ敪
      --       ,xql.usually_deliv_price         usually_deliv_price          -- �ʏ�X�[���i
      --       ,xql.this_time_deliv_price       this_time_deliv_price        -- ����X�[���i
      --       ,xql.usually_store_sale_price    usually_store_sale_price     -- �ʏ�X�����i
      --       ,xql.quotation_price             quotation_price              -- ���l
      --       ,xql.this_time_store_sale_price  this_time_store_sale_price   -- ����X�����i
      --       ,xql.usuall_net_price            usuall_net_price             -- �ʏ�NET���i
      --       ,xql.this_time_net_price         this_time_net_price          -- ����NET���i
      --       ,xql.amount_of_margin            amount_of_margin             -- �}�[�W���z
      --       ,xql.margin_rate                 margin_rate                  -- �}�[�W����
      --       ,xql.sales_discount_price        sales_discount_price         -- ����l��
      --       ,xql.business_price              business_price               -- �c�ƌ���
      --       ,xql.quote_start_date            quote_start_date             -- �L������(��)
      --       ,xql.quote_end_date              quote_end_date               -- �L������(��)
      --       ,xql.remarks                     remarks                      -- ���l
      --       ,xql.line_order                  line_order                   -- ���я�
      --       ,xql.last_update_date            last_update_date             -- �ŏI�X�V��
      SELECT TRANSLATE(xql.quote_line_id, CHR(10), ' ')              quote_line_id              -- ����ID
            ,TRANSLATE(xrh.quote_number, CHR(10), ' ')               quote_number               -- ���Ϗ��ԍ�
            ,TRANSLATE(msib.segment1, CHR(10), ' ')                  inventory_item_code        -- ���i�R�[�h
            ,TRANSLATE(xql.quote_div, CHR(10), ' ')                  quote_div                  -- ���ϋ敪
            ,TRANSLATE(xql.usually_deliv_price, CHR(10), ' ')        usually_deliv_price        -- �ʏ�X�[���i
            ,TRANSLATE(xql.this_time_deliv_price, CHR(10), ' ')      this_time_deliv_price      -- ����X�[���i
            ,TRANSLATE(xql.usually_store_sale_price, CHR(10), ' ')   usually_store_sale_price   -- �ʏ�X�����i
            ,TRANSLATE(xql.quotation_price, CHR(10), ' ')            quotation_price            -- ���l
            ,TRANSLATE(xql.this_time_store_sale_price, CHR(10), ' ') this_time_store_sale_price -- ����X�����i
            ,TRANSLATE(xql.usuall_net_price, CHR(10), ' ')           usuall_net_price           -- �ʏ�NET���i
            ,TRANSLATE(xql.this_time_net_price, CHR(10), ' ')        this_time_net_price        -- ����NET���i
            ,TRANSLATE(xql.amount_of_margin, CHR(10), ' ')           amount_of_margin           -- �}�[�W���z
            ,TRANSLATE(xql.margin_rate, CHR(10), ' ')                margin_rate                -- �}�[�W����
            ,TRANSLATE(xql.sales_discount_price, CHR(10), ' ')       sales_discount_price       -- ����l��
            ,TRANSLATE(xql.business_price, CHR(10), ' ')             business_price             -- �c�ƌ���
            ,TRANSLATE(xql.quote_start_date, CHR(10), ' ')           quote_start_date           -- �L������(��)
            ,TRANSLATE(xql.quote_end_date, CHR(10), ' ')             quote_end_date             -- �L������(��)
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xql.remarks, CHR(10) || CHR(13), '  ')), 1, 20)  remarks                    -- ���l
            ,TRANSLATE(xql.line_order, CHR(10), ' ')                 line_order                 -- ���я�
            ,TRANSLATE(xql.last_update_date, CHR(10), ' ')           last_update_date           -- �ŏI�X�V��
      /* 2009.04.16 K.Satomura T1_0172,T1_0508�Ή� END */
      FROM   xxcso_quote_lines     xql        -- ���ϖ��׃e�[�u��
             ,xxcso_quote_headers  xrh        -- ���σw�b�_�[�e�[�u��
             ,mtl_system_items_b   msib       -- Disc�i�ڃ}�X�^
      WHERE  xql.quote_header_id = it_qt_hdr_id
        AND  xql.quote_header_id = xrh.quote_header_id
        AND  msib.inventory_item_id = xql.inventory_item_id
        AND  msib.organization_id   = TO_NUMBER(lv_org_id)
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_headers_data_rec   get_headers_data_cur%ROWTYPE;
    l_get_lines_data_rec     get_lines_data_cur%ROWTYPE;
    l_get_hdr_data_rec       g_get_data_hdr_rtype;
    l_get_lns_data_rec       g_get_data_lns_rtype;
    -- *** ���[�J����O ***
    error_skip_data_expt           EXCEPTION;   -- �����X�L�b�v��O
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
    -- IN�p�����[�^�i�[
    lv_from_value := iv_from_value;  -- �p�����[�^�X�V�� FROM
    lv_to_value   := iv_to_value;    -- �p�����[�^�X�V�� TO
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
      iv_from_value   => lv_from_value       --   �p�����[�^�X�V�� FROM
     ,iv_to_value     => lv_to_value         --   �p�����[�^�X�V�� TO
     ,od_sysdate      => ld_sysdate          -- �V�X�e�����t
     ,od_process_date => ld_process_date     -- �Ɩ��������t
     ,ov_errbuf       => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.�p�����[�^�f�t�H���g�Z�b�g
    -- ========================================
    set_param_default(
      id_process_date  => ld_process_date    -- �Ɩ��������t    
     ,io_from_value    => lv_from_value      -- �p�����[�^�X�V�� FROM
     ,io_to_value      => lv_to_value        -- �p�����[�^�X�V�� TO
     ,ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-3.�p�����[�^�`�F�b�N
    -- ========================================
    chk_param(
      io_from_value   => lv_from_value     -- �p�����[�^�X�V�� FROM
     ,io_to_value     => lv_to_value       -- �p�����[�^�X�V�� TO
     ,ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.�v���t�@�C���l�擾
    -- ========================================
    get_profile_info(
      ov_company_cd   => lv_company_cd     -- ��ЃR�[�h�i�Œ�l001�j
     ,ov_csv_dir      => lv_csv_dir        -- CSV�t�@�C���o�͐�
     ,ov_csv_nm_hdr   => lv_csv_nm_hdr     -- CSV�t�@�C����(���σw�b�_)
     ,ov_csv_nm_lns   => lv_csv_nm_lns     -- CSV�t�@�C����(���ϖ���)
     ,ov_org_id       => lv_org_id         -- ORG_ID
     ,ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.���σw�b�_���CSV�t�@�C���I�[�v��
    -- ========================================
    open_csv_file_header(
      iv_csv_dir      => lv_csv_dir        -- CSV�t�@�C���o�͐�
     ,iv_csv_nm       => lv_csv_nm_hdr     -- CSV�t�@�C����(���σw�b�_)
     ,ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-6.���ϖ��׏��CSV�t�@�C���I�[�v��
    -- ========================================
    open_csv_file_lines(
      iv_csv_dir      => lv_csv_dir        -- CSV�t�@�C���o�͐�
     ,iv_csv_nm       => lv_csv_nm_lns     -- CSV�t�@�C����(���ϖ���)
     ,ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-7.���σw�b�_��񒊏o����
    -- ========================================
    -- �p�����[�^�X�V�� �ҏW
    ld_from_value := TO_DATE(lv_from_value,'yyyymmdd');
    ld_to_value   := TO_DATE(lv_to_value,'yyyymmdd');
--
    -- �J�[�\���I�[�v��
    OPEN get_headers_data_cur;
--
    <<get_hdr_data_loop>>
    LOOP
--
      BEGIN
--
        FETCH get_headers_data_cur INTO l_get_headers_data_rec;
        -- �����Ώی����i�[
        gn_target_cnt := get_headers_data_cur%ROWCOUNT;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_headers_data_cur%NOTFOUND
        OR  get_headers_data_cur%ROWCOUNT = 0;
--
        -- ���R�[�h�ϐ�������
        l_get_hdr_data_rec := NULL;
        -- �擾�f�[�^���i�[
        l_get_hdr_data_rec.company_cd             := lv_company_cd;                                 -- ��ЃR�[�h
        l_get_hdr_data_rec.quote_number           := l_get_headers_data_rec.quote_number;           -- ���Ϗ��ԍ�
        l_get_hdr_data_rec.reference_quote_number := l_get_headers_data_rec.reference_quote_number; -- �Q�ƌ��Ϗ��ԍ�
        l_get_hdr_data_rec.quote_revision_number  := l_get_headers_data_rec.quote_revision_number;  -- �Ő�
        l_get_hdr_data_rec.quote_type             := l_get_headers_data_rec.quote_type;             -- ���ώ��
        l_get_hdr_data_rec.account_number         := l_get_headers_data_rec.account_number;         -- �ڋq�R�[�h
        l_get_hdr_data_rec.publish_date           := l_get_headers_data_rec.publish_date;           -- ���s��
        l_get_hdr_data_rec.employee_number        := l_get_headers_data_rec.employee_number;        -- �S���҃R�[�h
        l_get_hdr_data_rec.deliv_place            := l_get_headers_data_rec.deliv_place;            -- �[���ꏊ
        l_get_hdr_data_rec.quote_info_start_date  := l_get_headers_data_rec.quote_info_start_date;  -- ���Ϗ�����(��)
        l_get_hdr_data_rec.quote_info_end_date    := l_get_headers_data_rec.quote_info_end_date;    -- ���Ϗ�����(��)
        l_get_hdr_data_rec.quote_submit_name      := l_get_headers_data_rec.quote_submit_name;      -- ���Ϗ���o�於��
        l_get_hdr_data_rec.special_note           := l_get_headers_data_rec.special_note;           -- ���L����
        l_get_hdr_data_rec.status                 := l_get_headers_data_rec.status;                 -- �X�e�[�^�X
        l_get_hdr_data_rec.deliv_price_tax_type   := l_get_headers_data_rec.deliv_price_tax_type;   -- �X�[���i�ŋ敪
        l_get_hdr_data_rec.unit_type              := l_get_headers_data_rec.unit_type;              -- �P���敪
        l_get_hdr_data_rec.cprtn_date             := ld_sysdate;                                    -- �A�g����
--
        -- ���ώ�ʂ������≮��p(2)�̏ꍇ
        IF (l_get_headers_data_rec.quote_type = cv_quote_type2) THEN
          -- ========================================
          -- A-8.�̔���p���σw�b�_�[���o
          -- ========================================
          get_xqh_data_for_sale(
             io_hdr_data_rec    => l_get_hdr_data_rec -- ���σw�b�_�f�[�^
            ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_warn) THEN
            RAISE error_skip_data_expt;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        -- ���ώ�ʂ��̔���p(1)�̏ꍇ
        ELSIF (l_get_headers_data_rec.quote_type = cv_quote_type1) THEN
          -- ========================================
          -- A-9.�ڋq�g�p�ړI�}�X�^���o
          -- ========================================
          get_hcsu_data(
            id_process_date    => ld_process_date     -- �Ɩ��������t          
           ,io_hdr_data_rec    => l_get_hdr_data_rec  -- ���σw�b�_�f�[�^
           ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
           ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
           ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
        -- ========================================
        -- A-10.���ϖ��׏�񒊏o����
        -- ========================================
        -- �J�[�\���I�[�v��
        OPEN get_lines_data_cur( 
               it_qt_hdr_id => l_get_headers_data_rec.quote_header_id -- ���σw�b�_�[ID
             );
--
        <<get_lns_data_loop>>
        LOOP
          FETCH get_lines_data_cur INTO l_get_lines_data_rec;
--
          -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
          EXIT WHEN get_lines_data_cur%NOTFOUND
          OR  get_lines_data_cur%ROWCOUNT = 0;
--
          -- ���R�[�h�ϐ�������
          l_get_lns_data_rec := NULL;
          -- �擾�f�[�^���i�[
          l_get_lns_data_rec.company_cd                 := lv_company_cd;                                 -- ��ЃR�[�h
          l_get_lns_data_rec.quote_line_id              := l_get_lines_data_rec.quote_line_id;            -- ����ID
          l_get_lns_data_rec.quote_number               := l_get_lines_data_rec.quote_number;             -- ���Ϗ��ԍ�
          l_get_lns_data_rec.inventory_item_code        := l_get_lines_data_rec.inventory_item_code;      -- ���i�R�[�h
          l_get_lns_data_rec.quote_div                  := l_get_lines_data_rec.quote_div;                -- ���ϋ敪
          l_get_lns_data_rec.usually_deliv_price        := l_get_lines_data_rec.usually_deliv_price;      -- �ʏ�X�[���i
          l_get_lns_data_rec.this_time_deliv_price      := l_get_lines_data_rec.this_time_deliv_price;    -- ����X�[���i
          l_get_lns_data_rec.usually_store_sale_price   := l_get_lines_data_rec.usually_store_sale_price; -- �ʏ�X�����i
          l_get_lns_data_rec.quotation_price            := l_get_lines_data_rec.quotation_price;          -- ���l
          l_get_lns_data_rec.this_time_store_sale_price := l_get_lines_data_rec.this_time_store_sale_price; -- ����X�����i
          l_get_lns_data_rec.this_time_net_price        := l_get_lines_data_rec.this_time_net_price;      -- ����NET���i
          l_get_lns_data_rec.amount_of_margin           := l_get_lines_data_rec.amount_of_margin;         -- �}�[�W���z
          l_get_lns_data_rec.margin_rate                := l_get_lines_data_rec.margin_rate;              -- �}�[�W����
          l_get_lns_data_rec.sales_discount_price       := l_get_lines_data_rec.sales_discount_price;     -- �l��
          l_get_lns_data_rec.business_price             := l_get_lines_data_rec.business_price;           -- �c�ƌ���
          l_get_lns_data_rec.quote_start_date           := l_get_lines_data_rec.quote_start_date;         -- �L������(��)
          l_get_lns_data_rec.quote_end_date             := l_get_lines_data_rec.quote_end_date;           -- �L������(��)
          l_get_lns_data_rec.remarks                    := l_get_lines_data_rec.remarks;                  -- ���l
          l_get_lns_data_rec.line_order                 := l_get_lines_data_rec.line_order;               -- ���я�
          l_get_lns_data_rec.usuall_net_price           := l_get_lines_data_rec.usuall_net_price;         -- �ʏ�NET���i
          l_get_lns_data_rec.cprtn_date                 := ld_sysdate;                                    -- �A�g����
--
          -- ========================================
          -- A-11.���ϖ��׏��CSV�o��
          -- ========================================
          create_csv_rec_lines(
            i_lns_data_rec      => l_get_lns_data_rec   -- ���ϖ��׏��f�[�^
           ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
           ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
           ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP get_lns_data_loop;
        -- �J�[�\���N���[�Y
        CLOSE get_lines_data_cur;
        -- ========================================
        -- A-12.���σw�b�_�[���CSV�o��
        -- ========================================
        create_csv_rec_header(
          i_hdr_data_rec   => l_get_hdr_data_rec    -- ���σw�b�_�[���f�[�^
          ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
         );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- �̔���p�ڋq�R�[�h�擾���s�̂��߃X�L�b�v
        WHEN error_skip_data_expt THEN
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        -- �G���[�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- *** DEBUG_LOG ***
        -- �f�[�^�X�L�b�v�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip  || CHR(10) ||
                     lv_errbuf          || CHR(10) ||
                     ''
        );
        -- �S�̂̏����X�e�[�^�X�Ɍx���Z�b�g
        ov_retcode := cv_status_warn;
--
      END;
--
    END LOOP get_hdr_data_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_headers_data_cur;
--
--
    -- ========================================
    -- A-13.���ϖ��׏��CSV�t�@�C���N���[�Y����
    -- ========================================
    close_csv_file_lines(
      iv_csv_dir    => lv_csv_dir       -- CSV�t�@�C���o�͐�
     ,iv_csv_nm     => lv_csv_nm_lns    -- CSV�t�@�C����(���ϖ���)
     ,ov_errbuf     => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode    => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-14.���σw�b�_���CSV�t�@�C���N���[�Y����
    -- ========================================
    close_csv_file_header(
      iv_csv_dir    => lv_csv_dir       -- CSV�t�@�C���o�͐�
     ,iv_csv_nm     => lv_csv_nm_hdr    -- CSV�t�@�C����(���σw�b�_)
     ,ov_errbuf     => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode    => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_headers_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lines_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_headers_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lines_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_headers_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_lines_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_from_value IN  VARCHAR2           --   �p�����[�^�X�V�� FROM
    ,iv_to_value   IN  VARCHAR2           --   �p�����[�^�X�V�� TO
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_from_value  => iv_from_value
      ,iv_to_value    => iv_to_value
      ,ov_errbuf      => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
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
    -- A-8.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
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
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
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
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A03C;
/
