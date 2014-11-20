CREATE OR REPLACE PACKAGE BODY xxwsh430002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh430002c(body)
 * Description      : �q�֕ԕi�m����C���^�t�F�[�X
 * MD.050           : �q�֕ԕi T_MD050_BPO_430
 * MD.070           : �q�֕ԕi�m����C���^�t�F�[�X  T_MD070_BPO_43C
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  get_profile            �v���t�@�C���擾�v���V�[�W���iC-1�j
 *  get_rtn_info_mst       �q�֕ԕi��񒊏o�v���V�[�W���iC-2�j
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� �iC-3�j
 *  update_xxwsh_order_lines_all  �q�֕ԕi�C���^�t�F�[�X�σt���O�X�V�v���V�[�W��(C-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0  Oracle ���V����   ����쐬
 *  2008/03/14    1.1  Oracle ���V����   �����ύX�v��#16�Ή�
 *  2008/05/23    1.2  Oracle �Γn���a   ���o�����Ɍv��ς݋敪��ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0'; -- ����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1'; -- �x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2'; -- �G���[
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C'; -- �X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G'; -- �X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E'; -- �X�e�[�^�X(�G���[)
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
  check_format_expt         EXCEPTION;           -- �ړ��f�[�^���o�����ł̗�O
  check_lock_expt           EXCEPTION;           -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(100) := 'xxwsh430002c';      -- �p�b�P�[�W��
  gv_xxwsh                    CONSTANT VARCHAR2(100) := 'XXWSH';             -- �A�v���P�[�V�����Z�k��
  gv_profile                  CONSTANT VARCHAR2(100) := 'APP-XXWSH-11701';   -- �v���t�@�C���擾�G���[
  gv_file_data_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11702';   -- �Ώۃf�[�^����
  gv_lock_err                 CONSTANT VARCHAR2(100) := 'APP-XXWSH-11703';   -- ���b�N�G���[
  gv_file_priv_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11704';   -- �t�@�C���A�N�Z�X�����G���[
  gv_cur_close_err            CONSTANT VARCHAR2(100) := 'APP-XXWSH-11705';   -- �J�[�\���N���[�Y�G���[
  gv_output_msg               CONSTANT VARCHAR2(100) := 'APP-XXWSH-01701';   -- �o�͌���
  gv_err_cnt_msg              CONSTANT VARCHAR2(100) := 'APP-XXWSH-01702';   -- �G���[����
  gv_format_err               CONSTANT VARCHAR2(100) := 'APP-XXWSH-00001';   -- �t�H�[�}�b�g�G���[
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �q�֕ԕi�����i�[����e�[�u���^�̒�`
  TYPE order_header_id_type      IS TABLE OF xxwsh_order_headers_all.order_header_id%TYPE           INDEX BY BINARY_INTEGER;-- �󒍃w�b�_�A�h�I��ID
  TYPE request_no_type           IS TABLE OF xxwsh_order_headers_all.request_no%TYPE                INDEX BY BINARY_INTEGER;-- �˗�No
  TYPE arrival_date_type         IS TABLE OF xxwsh_order_headers_all.arrival_date%TYPE              INDEX BY BINARY_INTEGER;-- ���ד�
  TYPE deliver_from_type         IS TABLE OF xxwsh_order_headers_all.deliver_from%TYPE              INDEX BY BINARY_INTEGER;-- �o�׌��ۊǏꏊ
  TYPE head_sales_branch_type    IS TABLE OF xxwsh_order_headers_all.head_sales_branch%TYPE         INDEX BY BINARY_INTEGER;-- �Ǌ����_
  TYPE deliver_to_type           IS TABLE OF xxwsh_order_headers_all.deliver_to%TYPE                INDEX BY BINARY_INTEGER;-- �z����
  TYPE customer_code_type        IS TABLE OF xxwsh_order_headers_all.customer_code%TYPE             INDEX BY BINARY_INTEGER;-- �ڋq
  TYPE shipping_item_code_type   IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE          INDEX BY BINARY_INTEGER;-- �o�וi��
  TYPE parent_item_id_type       IS TABLE OF xxcmn_item_mst2_v.item_no%TYPE                         INDEX BY BINARY_INTEGER;-- �e�i�ڃR�[�h
  TYPE crowd_code_type           IS TABLE OF xxcmn_item_mst2_v.old_crowd_code%TYPE                  INDEX BY BINARY_INTEGER;-- �Q�R�[�h
  TYPE item_um_type              IS TABLE OF xxcmn_item_mst2_v.item_um%TYPE                         INDEX BY BINARY_INTEGER;-- �P��
  TYPE num_of_cases_type         IS TABLE OF xxcmn_item_mst2_v.num_of_cases%TYPE                    INDEX BY BINARY_INTEGER;-- ����
  TYPE shipped_quantity_type     IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE            INDEX BY BINARY_INTEGER;-- �o�׎��ѐ���
  TYPE lookup_type_type          IS TABLE OF xxwsh_shipping_class2_v.attribute_category%TYPE        INDEX BY BINARY_INTEGER;-- �Q�ƃ^�C�v
  TYPE attribute1_type           IS TABLE OF xxwsh_shipping_class2_v.invoice_class_1%TYPE           INDEX BY BINARY_INTEGER;-- �`��1
  TYPE attribute3_type           IS TABLE OF xxwsh_shipping_class2_v.send_data_type%TYPE            INDEX BY BINARY_INTEGER;-- �f�[�^���
  TYPE order_category_code_type  IS TABLE OF oe_transaction_types_all.order_category_code%TYPE      INDEX BY BINARY_INTEGER;-- �󒍃J�e�S��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_dest_path                 VARCHAR2(1000);      -- �t�@�C���i�[�f�B���N�g��
  gv_filename                  VARCHAR2(100);       -- �t�@�C����
  gn_output_cnt                NUMBER;              -- �o�͌���
--
  -- �q�֕ԕi��񒊏o�p
  gt_order_header_id_tbl       order_header_id_type;
  gt_request_no_tbl            request_no_type;
  gt_arrival_date_tbl          arrival_date_type;
  gt_deliver_from_tbl          deliver_from_type;
  gt_head_sales_branch_tbl     head_sales_branch_type;
  gt_deliver_to_tbl            deliver_to_type;
  gt_customer_code_tbl         customer_code_type;
  gt_shipping_item_code_tbl    shipping_item_code_type;
  gt_item_no_tbl               parent_item_id_type;
  gt_crowd_code_tbl            crowd_code_type;
  gt_item_um_tbl               item_um_type;
  gt_num_of_cases_tbl          num_of_cases_type;
  gt_shipped_quantity_tbl      shipped_quantity_type;
  gt_lookup_type_tbl           lookup_type_type;
  gt_attribute1_tbl            attribute1_type;
  gt_attribute3_tbl            attribute3_type;
  gt_order_category_code_tbl   order_category_code_type;
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C���擾(C-1)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
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
    cv_dest_path_token     CONSTANT VARCHAR2(80) := 'XXWSH:IF�t�@�C���i�[�f�B���N�g��_�q�֕ԕi�m����C���^�t�F�[�X';
    cv_filename_token      CONSTANT VARCHAR2(80) := 'XXWSH:IF�t�@�C����_�q�֕ԕi�m����C���^�t�F�[�X';
    cv_dest_path           CONSTANT VARCHAR2(30) := 'XXWSH_OB_IF_DEST_PATH_430A';
    cv_filename            CONSTANT VARCHAR2(30) := 'XXWSH_OB_IF_FILENAME_430A';
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
    -- �t�@�C���p�X�擾
    gv_dest_path := FND_PROFILE.VALUE(cv_dest_path);
    IF (gv_dest_path IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_profile ,'PROF_NAME',cv_dest_path_token);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C�����擾
    gv_filename  := FND_PROFILE.VALUE(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_profile ,'PROF_NAME',cv_filename_token);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_rtn_info_mst
   * Description      : �q�֕ԕi��񒊏o(C-2)
   ***********************************************************************************/
  PROCEDURE get_rtn_info_mst(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rtn_info_mst'; -- �v���O������
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
    cv_lookup_code     CONSTANT VARCHAR2(2)  := '04';
    cv_lookup_type_3   CONSTANT VARCHAR2(1)  := '3'; -- �o�׎x���敪�i�q�֕ԕi�j
    cv_tablename       CONSTANT VARCHAR2(30) := '�󒍃A�h�I��';
--
    -- *** ���[�J���ϐ� ***
    i                   NUMBER; -- ���[�v�J���E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- C-2�q�֕ԕi��񒊏o
    -- �s���b�N
    CURSOR rm_if_cur IS
    SELECT xoha.order_header_id,                            -- �󒍃w�b�_�A�h�I��ID
           xoha.request_no,                                 -- �˗�No
           xoha.arrival_date,                               -- ���ד�
           xoha.deliver_from,                               -- �o�׌��ۊǏꏊ
           xoha.head_sales_branch,                          -- �Ǌ����_
           xoha.deliver_to,                                 -- �z����
           xoha.customer_code,                              -- �ڋq
           xola.shipping_item_code,                         -- �o�וi��
           ximv2.item_no,                                   -- �e�i�ڃR�[�h
           CASE
             WHEN (TO_DATE(ximv1.crowd_start_date,'YYYY/MM/DD') <= xoha.arrival_date)
             THEN ximv1.new_crowd_code                      -- �V�Q�R�[�h
             ELSE ximv1.old_crowd_code                      -- ���Q�R�[�h
           END AS crowd_code,
           ximv1.item_um,                                   -- �P��
           NVL(ximv1.num_of_cases,0)    AS num_of_cases,    -- ����
           NVL(xola.shipped_quantity,0) AS shipped_quantity,-- �o�׎��ѐ���
           xscv.attribute_category,                         -- �o�׋敪����
           xscv.invoice_class_1,                            -- �`��1
           xscv.send_data_type,                             -- �f�[�^���
           xotv.order_category_code                         -- �󒍃J�e�S��
    FROM xxwsh_order_headers_all       xoha,                -- �󒍃w�b�_�A�h�I��
         xxwsh_order_lines_all         xola,                -- �󒍖��׃A�h�I��
         xxcmn_item_mst2_v             ximv1,               -- OPM�i�ڏ��VIEW(�q)
         xxcmn_item_mst2_v             ximv2,               -- OPM�i�ڏ��VIEW(�e)
         xxwsh_oe_transaction_types2_v xotv,                -- �󒍃^�C�vVIEW
         xxwsh_shipping_class2_v       xscv                 -- �o�׋敪���VIEW
    WHERE xoha.req_status            = cv_lookup_code                   -- �X�e�[�^�X(�o�׎��ьv���)
      AND xoha.order_type_id         = xotv.transaction_type_id         -- ����^�C�vID�i�󒍃^�C�vID�j
      AND xoha.actual_confirm_class  = 'Y'                              -- ����^�C�vID�i�󒍃^�C�vID�j
      AND xotv.shipping_shikyu_class = cv_lookup_type_3                 -- �o�׎x���敪
      AND xotv.transaction_type_name = xscv.order_transaction_type_name -- �󒍃^�C�v��
      AND xoha.order_header_id       = xola.order_header_id             -- �󒍃w�b�_�A�h�I��ID
      AND xola.shipping_item_code    = ximv1.item_no                    -- �i��(�q)
      AND ximv1.start_date_active   <= xoha.arrival_date                -- �K�p�J�n��(�q)
      AND ximv1.end_date_active     >= xoha.arrival_date                -- �K�p�I����(�q)
      AND ximv1.parent_item_id       = ximv2.item_id                    -- �i�ڃR�[�h(�e�q)
      AND ximv2.start_date_active   <= xoha.arrival_date                -- �K�p�J�n��(�e)
      AND ximv2.end_date_active     >= xoha.arrival_date                -- �K�p�I����(�e)
      AND xola.rm_if_flg           IS NULL                              -- �q�֕ԕi�C���^�t�F�[�X�σt���O
    ORDER BY
       xoha.ordered_date          -- �󒍓�
      ,xoha.deliver_from          -- �o�׌��ۊǏꏊ
      ,xoha.head_sales_branch     -- �Ǌ����_
      ,xoha.result_deliver_to     -- �o�א�_����
      ,xoha.customer_code         -- �ڋq
      ,xola.shipping_item_code    -- �o�וi��(���ׁj
    FOR UPDATE OF xola.order_header_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    lr_rm_if_rec   rm_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN rm_if_cur;-- �J�[�\���I�[�v��
--
    i := 0;
    <<rm_if_cur_loop>>
    LOOP
      -- ���R�[�h�Ǎ�
      FETCH rm_if_cur INTO lr_rm_if_rec;
      EXIT WHEN rm_if_cur%NOTFOUND;
--
      i := i + 1;
--
      gt_order_header_id_tbl(i)      := lr_rm_if_rec.order_header_id;      -- �󒍃w�b�_�A�h�I��ID
      gt_request_no_tbl(i)           := lr_rm_if_rec.request_no;           -- �˗�No
      gt_arrival_date_tbl(i)         := lr_rm_if_rec.arrival_date;         -- ���ד�
      gt_deliver_from_tbl(i)         := lr_rm_if_rec.deliver_from;         -- �o�׌��ۊǏꏊ
      gt_head_sales_branch_tbl(i)    := lr_rm_if_rec.head_sales_branch;    -- �Ǌ����_
      gt_deliver_to_tbl(i)           := NULL;                              -- �z����
      gt_customer_code_tbl(i)        := NULL;                              -- �ڋq
      gt_shipping_item_code_tbl(i)   := lr_rm_if_rec.shipping_item_code;   -- �o�וi��
      gt_item_no_tbl(i)              := lr_rm_if_rec.item_no;              -- �e�i�ڃR�[�h
      gt_crowd_code_tbl(i)           := lr_rm_if_rec.crowd_code;           -- �Q�R�[�h
      gt_item_um_tbl(i)              := lr_rm_if_rec.item_um;              -- �P��
      gt_num_of_cases_tbl(i)         := lr_rm_if_rec.num_of_cases;         -- ����
      gt_shipped_quantity_tbl(i)     := lr_rm_if_rec.shipped_quantity;     -- �o�׎��ѐ���
      gt_lookup_type_tbl(i)          := lr_rm_if_rec.attribute_category;   -- �Q�ƃ^�C�v
      gt_attribute1_tbl(i)           := lr_rm_if_rec.invoice_class_1;      -- �`��1
      gt_attribute3_tbl(i)           := lr_rm_if_rec.send_data_type;       -- �f�[�^���
      gt_order_category_code_tbl(i)  := lr_rm_if_rec.order_category_code;  -- �󒍃J�e�S��
    END LOOP rm_if_cur_loop;
--
    CLOSE rm_if_cur;
--
    -- 1�������o�ł��Ȃ������ꍇ�A�x��
    IF (i = 0) THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_data_err,'TABLE',cv_tablename);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,ov_errmsg);
      ov_retcode := gv_status_warn;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN check_lock_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh, gv_lock_err);
      lv_errbuf := ov_errmsg;
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\����OPEN���Ă���ꍇ
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\����OPEN���Ă���ꍇ
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\����OPEN���Ă���ꍇ
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\����OPEN���Ă���ꍇ
      IF(rm_if_cur%ISOPEN) THEN
        CLOSE rm_if_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_rtn_info_mst;
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : �C���^�t�F�[�X�t�@�C���o��(C-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    cv_change_type        CONSTANT VARCHAR2(1) :=  '2';    -- �ϊ��敪
    cv_status_error       CONSTANT VARCHAR2(1) :=  '1';    -- �G���[�Ԃ�l
    cv_rno                CONSTANT VARCHAR2(1) :=  '0';    -- R No
    cv_voucher2           CONSTANT VARCHAR2(1) :=  '2';    -- �`��2
    cv_continue           CONSTANT VARCHAR2(2) := '00';    -- �p��
    cv_comma              CONSTANT VARCHAR2(1) :=  ',';    -- �J���}
    cv_order              CONSTANT VARCHAR2(5) := 'ORDER'; -- �󒍃J�e�S��
    cv_cases_value        CONSTANT VARCHAR2(8) := '�P�[�X��';
    cv_num_of_cases_value CONSTANT VARCHAR2(4) := '����'    ;
    cv_number_value       CONSTANT VARCHAR2(4) := '�{��'    ;
    cv_crowd_code         CONSTANT VARCHAR2(8) := '�Q�R�[�h';
    cn_cases_value        CONSTANT NUMBER      := 6;       -- �P�[�X������
    cn_num_of_cases_value CONSTANT NUMBER      := 4;       -- ��������
    cn_number_value       CONSTANT NUMBER      := 9;       -- �{������ ����
    cn_number_m_value     CONSTANT NUMBER      := 8;       -- �{������ ����
    cn_crowd_code         CONSTANT NUMBER      := 4;       -- �Q�R�[�h
    --
    -- *** ���[�J���ϐ� ***
    lv_after_request_no   VARCHAR2(9);      -- �ϊ���˗�No
    lv_csv_file           VARCHAR2(10000);  -- CSV�o�͏��
    ln_cases              NUMBER;           -- �P�[�X��
    ln_number             NUMBER;           -- �{��
    ln_retcode            NUMBER;           -- �Ԃ�l
    lf_file_hand    UTL_FILE.FILE_TYPE;     -- �t�@�C���E�n���h���̐錾
    lv_fmat               VARCHAR2(15);     -- �����p
    lv_clm_name           VARCHAR2(8);      -- ���ڊi�[�p
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    -- CSV�t�@�C���֏o��
    lf_file_hand := UTL_FILE.FOPEN(gv_dest_path,
                                   gv_filename,
                                   'w');
--
    <<gt_order_header_id_loop>>
    FOR i IN 1..gt_order_header_id_tbl.COUNT LOOP
--
      --�˗�No�R���o�[�g
      ov_retcode := xxwsh_common_pkg.convert_request_number(
                                                             cv_change_type       -- 1.�ϊ��敪
                                                            ,gt_request_no_tbl(i) -- 2.�ϊ��O�˗�No
                                                            ,lv_after_request_no  -- 3.�ϊ���˗�No
                                                           );
      -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
      IF(ov_retcode = cv_status_error)THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_data_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
--
      lv_fmat    := '999999999D99'; --�����p����
      -- �o�׎��ѐ��ʂ�0�̏ꍇ
      IF(gt_shipped_quantity_tbl(i) = 0) THEN
        ln_cases  := 0;  -- �P�[�X��
        ln_number := 0;  -- �{��
      -- ������0�̏ꍇ
      ELSIF(gt_num_of_cases_tbl(i) = 0) THEN
        ln_cases  := NULL;                          -- �P�[�X��
        ln_number := gt_shipped_quantity_tbl(i);    -- �{��
      ELSE
        ln_cases  := TRUNC(gt_shipped_quantity_tbl(i) / gt_num_of_cases_tbl(i));    -- �P�[�X��
        ln_number := TRUNC(MOD(gt_shipped_quantity_tbl(i),gt_num_of_cases_tbl(i))); -- �{��
      END IF;
--
      -- �󒍂̏ꍇ
      IF (gt_order_category_code_tbl(i) = cv_order) THEN
        IF(LENGTH(ln_number) > cn_number_m_value) THEN
          lv_clm_name := cv_number_value;
          RAISE check_format_expt;
        END IF;
        ln_cases  := ln_cases * -1;
        ln_number := ln_number * -1;
        lv_fmat   := '99999990D99'; --�����p����
      END IF;
--
      -- �����`�F�b�N
      --�P�[�X���̃`�F�b�N
      IF (LENGTH(ln_cases) > cn_cases_value) THEN
        lv_clm_name := cv_cases_value;
        RAISE check_format_expt;
      --����
      ELSIF(LENGTH(gt_num_of_cases_tbl(i)) > cn_num_of_cases_value)THEN
        lv_clm_name := cv_num_of_cases_value;
        RAISE check_format_expt;
      --�Q�R�[�h
      ELSIF(LENGTH(gt_crowd_code_tbl(i)) > cn_crowd_code)THEN
        lv_clm_name := cv_crowd_code;
        RAISE check_format_expt;
      --�{���̃`�F�b�N
      ELSIF(LENGTH(ln_number) > cn_number_value) THEN
        lv_clm_name := cv_number_value;
        RAISE check_format_expt;
      END IF;
--
      --CSV�t�@�C���o��
      lv_csv_file := gt_attribute3_tbl(i) || cv_comma
                                          || cv_rno                                     ||cv_comma
                                          || cv_continue                                ||cv_comma
                                          || TO_CHAR(gt_arrival_date_tbl(i),'YYYYMM')   ||cv_comma
                                          || gt_deliver_from_tbl(i)                     ||cv_comma
                                          || gt_head_sales_branch_tbl(i)                ||cv_comma
                                          || gt_attribute1_tbl(i)                       ||cv_comma
                                          || cv_voucher2                                ||cv_comma
                                          || gt_deliver_to_tbl(i)                       ||cv_comma
                                          || gt_customer_code_tbl(i)                    ||cv_comma
                                          || TO_CHAR(gt_arrival_date_tbl(i),'YYYYMMDD') ||cv_comma
                                          || lv_after_request_no                        ||cv_comma
                                          || gt_shipping_item_code_tbl(i)               ||cv_comma
                                          || gt_item_no_tbl(i)                          ||cv_comma
                                          || gt_crowd_code_tbl(i)                       ||cv_comma
                                          || TO_CHAR(ln_cases,'999999')                 ||cv_comma
                                          || TO_CHAR(gt_num_of_cases_tbl(i) ,'9999')    ||cv_comma
                                          || TO_CHAR(ln_number,lv_fmat);
--
      -- CSV�t�@�C���֏o�͂���ꍇ
      UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
      -- �o�͌���
      gn_target_cnt := gn_target_cnt +1;
    END LOOP gt_item_mst_tbl_loop;
--
    --�t�@�C���N���[�Y
    UTL_FILE.FCLOSE(lf_file_hand);
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �����G���[
    WHEN check_format_expt THEN
      -- �t�@�C����OPEN����Ă���Ƃ�
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_format_err,'CLM_NAME',lv_clm_name);
      ov_retcode := gv_status_error;
    -- �t�@�C���A�N�Z�X�����G���[
    WHEN UTL_FILE.ACCESS_DENIED THEN
      -- �t�@�C����OPEN����Ă���Ƃ�
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_file_priv_err);
      lv_errbuf := lv_errmsg;
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �t�@�C����OPEN����Ă���Ƃ�
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C����OPEN����Ă���Ƃ�
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C����OPEN����Ă���Ƃ�
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
  /**********************************************************************************
   * Procedure Name   : update_xxwsh_order_lines_all
   * Description      : �q�֕ԕi�C���^�t�F�[�X�σt���O�X�V(C-4)
   ***********************************************************************************/
  PROCEDURE update_xxwsh_order_lines_all(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_xxwsh_order_lines_all'; -- �v���O������
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
    lv_rm_if_flg  VARCHAR2(2) :=  'Y';
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
    --�q�֕ԕi�C���^�t�F�[�X�σt���O�̍X�V
    FORALL i IN 1 .. gt_order_header_id_tbl.COUNT
      UPDATE xxwsh_order_lines_all
         SET rm_if_flg                   = lv_rm_if_flg               -- �q�֕ԕi�C���^�t�F�[�X�σt���O
           , last_updated_by             = FND_GLOBAL.USER_ID         -- �ŏI�X�V��
           , last_update_date            = SYSDATE                    -- �ŏI�X�V��
           , last_update_login           = FND_GLOBAL.LOGIN_ID        -- �ŏI�X�V���O�C��
           , request_id                  = FND_GLOBAL.CONC_REQUEST_ID -- �v��ID
           , program_application_id      = FND_GLOBAL.PROG_APPL_ID    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����id
           , program_id                  = FND_GLOBAL.CONC_PROGRAM_ID -- �R���J�����g�E�v���O����id
           , program_update_date         = SYSDATE                    -- �v���O�����X�V��
       WHERE order_header_id             = gt_order_header_id_tbl(i); -- �󒍃w�b�_�A�h�I��ID
--
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
  END update_xxwsh_order_lines_all;
--
/**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_output_cnt := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �v���t�@�C���擾 (C-1)
    -- ===============================
    get_profile(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- �q�֕ԕi��񒊏o (C-2)
    -- ===============================
    get_rtn_info_mst(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- CSV�ւ̏o��(C-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    -- ==============================================
    -- �q�֕ԕi�C���^�t�F�[�X�ς݃t���O�X�V(C-4)
    -- ==============================================
    update_xxwsh_order_lines_all(
                               lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                               lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                               lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
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
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�o�͌����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH',gv_output_msg,'CNT',TO_CHAR(gn_target_cnt));
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
END xxwsh430002c;
/
