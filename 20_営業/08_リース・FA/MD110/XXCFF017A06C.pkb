CREATE OR REPLACE PACKAGE BODY APPS.XXCFF017A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A06C (spec)
 * Description      : ���Y���Z����������X�g
 * MD.050           : ���Y���Z����������X�g (MD050_CFF_017A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             ���Y�䒠��񒊏o����(A-2)�A���Y���Z����������X�g�o�͏���(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/06/17    1.0   T.Kobori         main�V�K�쐬
 *  2014/07/04    1.1   T.Kobori         ���ڒǉ�  1.�d����R�[�h
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
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
  init_err_expt               EXCEPTION;      -- ���������G���[
  no_data_warn_expt           EXCEPTION;      -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A06C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcff          CONSTANT VARCHAR2(10)  := 'XXCFF';                     -- XXCFF
  -- ���t����
  cv_format_YMD               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_format_std               CONSTANT VARCHAR2(50)  := 'yyyy/mm/dd hh24:mi:ss';
  -- ���蕶��
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cff_00020            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00020';          -- �v���t�@�C���擾�G���[
  cv_msg_cff_00062            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00062';          -- �Ώۃf�[�^����
  cv_msg_cff_00092            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00092';          -- �Ɩ��������t�擾�G���[
  cv_msg_cff_00220            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00220';          -- ���̓p�����[�^
  cv_msg_cff_00230            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-00230';          -- ���̓p�����[�^�`�F�b�N�G���[
  cv_msg_cff_50241            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50241';          -- ���b�Z�[�W�p������(���Y�ԍ�)
  cv_msg_cff_50010            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50010';          -- ���b�Z�[�W�p������(�����R�[�h)
  cv_msg_cff_50274            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50274';          -- ���b�Z�[�W�p������(��ЃR�[�h)
  cv_msg_cff_50276            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50276';          -- ���b�Z�[�W�p������(�d����R�[�h)
  cv_msg_cff_50242            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50242';          -- ���b�Z�[�W�p������(�E�v)
  cv_msg_cff_50247            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50247';          -- ���b�Z�[�W�p������(���Ƌ��p�� FROM)
  cv_msg_cff_50248            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50248';          -- ���b�Z�[�W�p������(���Ƌ��p�� TO)
  cv_msg_cff_50244            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50244';          -- ���b�Z�[�W�p������(�擾���i FROM)
  cv_msg_cff_50245            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50245';          -- ���b�Z�[�W�p������(�擾���i TO)
  cv_msg_cff_50270            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50270';          -- ���b�Z�[�W�p������(���Y����)
  cv_msg_cff_50271            CONSTANT VARCHAR2(50)  := 'APP-XXCFF1-50271';          -- ���Y�䒠CSV�o�̓w�b�_�m�[�g
  cv_msg_cff_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی������b�Z�[�W
  cv_msg_cff_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- �����������b�Z�[�W
  cv_msg_cff_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[�������b�Z�[�W
  cv_msg_cff_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';          -- �X�L�b�v�������b�Z�[�W
  cv_msg_cff_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I�����b�Z�[�W
  cv_msg_cff_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- �x�����b�Z�[�W
  cv_msg_cff_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N���b�Z�[�W
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���̓p�����[�^��
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���̓p�����[�^�l
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- �v���t�@�C����
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
  -- �v���t�@�C����
  cv_prof_fixed_assets_books  CONSTANT VARCHAR2(50)  := 'XXCFF1_FIXED_ASSETS_BOOKS'; -- �䒠��
  -- �Œ�l
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                        -- ���{��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_asset_number                    FA_ADDITIONS_B.ASSET_NUMBER%TYPE;         -- ���Y�ԍ�
  gt_object_code                     FA_ADDITIONS_B.TAG_NUMBER%TYPE;           -- �����R�[�h
  gt_segment1                        GL_CODE_COMBINATIONS.SEGMENT1%TYPE;       -- ��ЃR�[�h
  gt_vendor_code                     PO_VENDORS.SEGMENT1%TYPE;                 -- �d����R�[�h
  gt_description                     FA_ADDITIONS_TL.DESCRIPTION%TYPE;         -- �E�v
  gd_date_placed_in_service_from     DATE;                                     -- ���Ƌ��p�� FROM
  gd_date_placed_in_service_to       DATE;                                     -- ���Ƌ��p�� TO
  gt_original_cost_from              FA_BOOKS.ORIGINAL_COST%TYPE;              -- �擾���i FROM
  gt_original_cost_to                FA_BOOKS.ORIGINAL_COST%TYPE;              -- �擾���i TO
  gt_segment3                        FA_CATEGORIES_VL.SEGMENT3%TYPE;           -- ���Y�Ȗ�
  gt_book_type_code                  FA_BOOKS.BOOK_TYPE_CODE%TYPE;             -- �䒠��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ���Y�䒠���擾�J�[�\��
  CURSOR get_fa_books_info_cur
  IS
    SELECT
        fab.asset_number           AS asset_number                         -- ���Y�ԍ�
       ,fab.tag_number             AS tag_number                           -- �����R�[�h
       ,gcc.segment1               AS segment1                             -- �{�ЍH��
 -- 2014/07/04 ADD START
       ,vohd.vendor_code           AS vendor_code                          -- �d����R�[�h
 -- 2014/07/04 ADD END
       ,fat.description            AS description                          -- �E�v
       ,fb.date_placed_in_service  AS date_placed_in_service               -- ���Ƌ��p��
       ,fb.original_cost           AS original_cost                        -- �擾���i
    FROM
        APPS.FA_ADDITIONS_B fab                                            -- ���Y�ڍ׏��
       ,APPS.FA_BOOKS fb                                                   -- ���Y�䒠���
       ,APPS.FA_ADDITIONS_TL fat                                           -- ���Y�E�v���
       ,APPS.FA_DISTRIBUTION_HISTORY fdh                                   -- ���Y�����������
       ,APPS.FA_CATEGORIES_VL fcv                                          -- ���Y�J�e�S���}�X�^�r���[
       ,APPS.GL_CODE_COMBINATIONS gcc                                      -- GL�g����
 -- 2014/07/04 ADD START
       ,xxcff_vd_object_headers vohd                                       -- ���̋@�����Ǘ�
 -- 2014/07/04 ADD END
    WHERE fab.ASSET_ID = fb.ASSET_ID                                   -- ���Y�ԍ�ID
    AND fat.ASSET_ID = fab.ASSET_ID                                    -- ���Y�ԍ�ID
    AND fab.asset_id = fdh.asset_id                                    -- ���Y�ԍ�ID
    AND fat.LANGUAGE = cv_language_ja                                  -- ����
    AND fb.BOOK_TYPE_CODE = gt_book_type_code                          -- �v���t�@�C���l�i'�Œ莑�Y�䒠'�j
    AND fcv.CATEGORY_ID = fab.ASSET_CATEGORY_ID                        -- ���Y�J�e�S��ID
    AND fb.DATE_INEFFECTIVE IS NULL                                    -- ������
    AND fcv.DATE_INEFFECTIVE IS NULL                                   -- ������
    AND fdh.date_ineffective IS NULL                                   -- ������
    AND gcc.code_combination_id  = fdh.code_combination_id             -- �g����ID
 -- 2014/07/04 ADD START
    AND fab.tag_number = vohd.object_code (+)                          -- �����R�[�h
 -- 2014/07/04 ADD END
    AND fab.asset_number               = NVL(gt_asset_number,fab.asset_number)       -- ���Y�ԍ�
    AND (  gt_object_code IS NULL
        OR fab.tag_number              = gt_object_code            -- �����R�[�h
        )
    AND (  gt_segment1 IS NULL
        OR gcc.segment1                = gt_segment1               -- ��ЃR�[�h
        )
 -- 2014/07/04 ADD START
    AND (  gt_vendor_code IS NULL
        OR vohd.vendor_code            = gt_vendor_code            -- �d����R�[�h
        )
 -- 2014/07/04 ADD END
    AND (  gt_description IS NULL
        OR fat.description             LIKE gt_description         -- �E�v
        )
    AND fb.date_placed_in_service     >= NVL(gd_date_placed_in_service_from,fb.date_placed_in_service)   -- ���Ƌ��p�� FROM
    AND fb.date_placed_in_service     <= NVL(gd_date_placed_in_service_to,fb.date_placed_in_service)     -- ���Ƌ��p�� TO
    AND fb.original_cost              >= NVL(gt_original_cost_from,fb.original_cost)                     -- �擾���i FROM
    AND fb.original_cost              <= NVL(gt_original_cost_to,fb.original_cost)                       -- �擾���i TO
    AND fcv.segment3                   = NVL(gt_segment3,fcv.segment3)                                   -- ���Y�Ȗ�
    ORDER BY tag_number           -- �����R�[�h
            ,asset_number         -- ���Y�ԍ�
    ;
    -- ���Y�䒠���J�[�\�����R�[�h�^
    get_fa_books_info_rec get_fa_books_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_asset_number                 IN  VARCHAR2      -- 1.���Y�ԍ�
   ,iv_object_code                  IN  VARCHAR2      -- 2.�����R�[�h
   ,iv_segment1                     IN  VARCHAR2      -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2      -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2      -- 4.�E�v
   ,iv_date_placed_in_service_from  IN  DATE          -- 5.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  DATE          -- 6.���Ƌ��p�� TO
   ,iv_original_cost_from           IN  VARCHAR2      -- 7.�擾���i FROM
   ,iv_original_cost_to             IN  VARCHAR2      -- 8.�擾���i TO
   ,iv_segment3                     IN  VARCHAR2      -- 9.���Y����
   ,ov_errbuf                       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_param_name1                  VARCHAR2(1000);  -- ���̓p�����[�^��1
    lv_param_name2                  VARCHAR2(1000);  -- ���̓p�����[�^��2
    lv_param_name3                  VARCHAR2(1000);  -- ���̓p�����[�^��3
    lv_param_name4                  VARCHAR2(1000);  -- ���̓p�����[�^��4
    lv_param_name5                  VARCHAR2(1000);  -- ���̓p�����[�^��5
    lv_param_name6                  VARCHAR2(1000);  -- ���̓p�����[�^��6
    lv_param_name7                  VARCHAR2(1000);  -- ���̓p�����[�^��7
    lv_param_name8                  VARCHAR2(1000);  -- ���̓p�����[�^��8
    lv_param_name9                  VARCHAR2(1000);  -- ���̓p�����[�^��9
 -- 2014/07/04 ADD START
    lv_param_name10                 VARCHAR2(1000);  -- ���̓p�����[�^��10
 -- 2014/07/04 ADD END
    lv_asset_number                 VARCHAR2(1000);  -- 1.���Y�ԍ�
    lv_object_code                  VARCHAR2(1000);  -- 2.�����R�[�h
    lv_segment1                     VARCHAR2(1000);  -- 3.��ЃR�[�h
    lv_description                  VARCHAR2(1000);  -- 4.�E�v
    lv_date_placed_in_service_from  VARCHAR2(1000);  -- 5.���Ƌ��p�� FROM
    lv_date_placed_in_service_to    VARCHAR2(1000);  -- 6.���Ƌ��p�� TO
    lv_original_cost_from           VARCHAR2(1000);  -- 7.�擾���i FROM
    lv_original_cost_to             VARCHAR2(1000);  -- 8.�擾���i TO
    lv_segment3                     VARCHAR2(1000);  -- 9.���Y����
 -- 2014/07/04 ADD START
    lv_vendor_code                  VARCHAR2(1000);  -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
    lv_csv_header                   VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
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
    --==============================================================
    -- 0.���̓p�����[�^�i�[
    --==============================================================
    gt_asset_number                 := iv_asset_number;                           --1.���Y�ԍ�
    gt_object_code                  := iv_object_code;                            --2.�����R�[�h
    gt_segment1                     := iv_segment1;                               --3.��ЃR�[�h
    gt_description                  := iv_description;                            --4.�E�v
    gd_date_placed_in_service_from  := iv_date_placed_in_service_from;            --5.���Ƌ��p�� FROM
    gd_date_placed_in_service_to    := iv_date_placed_in_service_to;              --6.���Ƌ��p�� TO
    gt_original_cost_from           := TO_NUMBER(iv_original_cost_from);          --7.�擾���i FROM
    gt_original_cost_to             := TO_NUMBER(iv_original_cost_to);            --8.�擾���i TO
    gt_segment3                     := iv_segment3;                               --9.���Y����
 -- 2014/07/04 ADD START
    gt_vendor_code                     := iv_vendor_code;                               --10.�d����R�[�h
 -- 2014/07/04 ADD END
--
    --==============================================================
    -- 1.���̓p�����[�^�o��
    --==============================================================
    -- 1.���Y�ԍ�
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50241               -- ���b�Z�[�W�R�[�h
                      );
    lv_asset_number := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name1                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_asset_number                -- �g�[�N���l2
                      );
--
    -- 2.�����R�[�h
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50010               -- ���b�Z�[�W�R�[�h
                      );
    lv_object_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name2                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_object_code                 -- �g�[�N���l2
                      );
--
    -- 3.��ЃR�[�h
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50274               -- ���b�Z�[�W�R�[�h
                      );
    lv_segment1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name3                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_segment1                    -- �g�[�N���l2
                      );
--
    -- 4.�E�v
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50242               -- ���b�Z�[�W�R�[�h
                      );
    lv_description := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name4                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_description                 -- �g�[�N���l2
                      );
--
    -- 5.���Ƌ��p�� FROM
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50247               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_placed_in_service_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name5                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_date_placed_in_service_from -- �g�[�N���l2
                      );
--
    -- 6.���Ƌ��p�� TO
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50248               -- ���b�Z�[�W�R�[�h
                      );
    lv_date_placed_in_service_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name6                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_date_placed_in_service_to   -- �g�[�N���l2
                      );
--
    -- 7.�擾���i FROM
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50244               -- ���b�Z�[�W�R�[�h
                      );
    lv_original_cost_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name7                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_original_cost_from          -- �g�[�N���l2
                      );
--
    -- 8.�擾���i TO
    lv_param_name8 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50245               -- ���b�Z�[�W�R�[�h
                      );
    lv_original_cost_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name8                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_original_cost_to            -- �g �[�N���l2
                      );
--
    -- 9.���Y����
    lv_param_name9 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50270               -- ���b�Z�[�W�R�[�h
                      );
    lv_segment3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name9                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_segment3                    -- �g�[�N���l2
                      );
--
 -- 2014/07/04 ADD START
    -- 10.�d����R�[�h
    lv_param_name10 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_50276               -- ���b�Z�[�W�R�[�h
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcff             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cff_00220               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name10                 -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value             -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_vendor_code                    -- �g�[�N���l2
                      );
 -- 2014/07/04 ADD END
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                             || CHR(10) ||
                 lv_asset_number                || CHR(10) ||      -- 1.���Y�ԍ�
                 lv_object_code                 || CHR(10) ||      -- 2.�����R�[�h
                 lv_segment1                    || CHR(10) ||      -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
                 lv_vendor_code                 || CHR(10) ||      -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
                 lv_description                 || CHR(10) ||      -- 4.�E�v
                 lv_date_placed_in_service_from || CHR(10) ||      -- 5.���Ƌ��p�� FROM
                 lv_date_placed_in_service_to   || CHR(10) ||      -- 6.���Ƌ��p�� TO
                 lv_original_cost_from          || CHR(10) ||      -- 7.�擾���i FROM
                 lv_original_cost_to            || CHR(10) ||      -- 8.�擾���i TO
                 lv_segment3                    || CHR(10)         -- 9.���Y����
    );
--
    --==================================================
    -- 2.�v���t�@�C���l�擾
    --==================================================
    gt_book_type_code := FND_PROFILE.VALUE( cv_prof_fixed_assets_books );
    -- �v���t�@�C���̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gt_book_type_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff         -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cff_00020           -- ���b�Z�[�W�R�[�h
         ,iv_token_name1  => cv_tkn_prof_name           -- �g�[�N���R�[�h1
         ,iv_token_value1 => cv_prof_fixed_assets_books -- �g�[�N���l1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.���̓p�����[�^�L���`�F�b�N
    --==================================================
    -- ���̓p�����[�^���S�Ė����͂̏ꍇ�̓G���[
    IF( gt_asset_number                IS NULL AND     -- 1.���Y�ԍ�
        gt_object_code                 IS NULL AND     -- 2.�����R�[�h
        gt_segment1                    IS NULL AND     -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
        gt_vendor_code                 IS NULL AND     -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
        gt_description                 IS NULL AND     -- 4.�E�v
        gd_date_placed_in_service_from IS NULL AND     -- 5.���Ƌ��p�� FROM
        gd_date_placed_in_service_to   IS NULL AND     -- 6.���Ƌ��p�� TO
        gt_original_cost_from          IS NULL AND     -- 7.�擾���i FROM
        gt_original_cost_to            IS NULL AND     -- 8.�擾���i TO
        gt_segment3                    IS NULL )       -- 9.���Y����
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcff   -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cff_00230     -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 4.CSV�w�b�_���ڏo��
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cff_50271     -- ���b�Z�[�W�R�[�h
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : ���Y�䒠��񒊏o����(A-2)�A���Y���Z����������X�g�o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
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
--
    -- *** ���[�J���ϐ� ***
    lv_op_str            VARCHAR2(5000)  := NULL;   -- �o�͕�����i�[�p�ϐ�
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- ���Y�䒠��񒊏o����(A-2)
    -- ===============================
    << fa_books_info_loop >>
    FOR get_fa_books_info_rec IN get_fa_books_info_cur
    LOOP
      -- ===============================
      -- CSV�t�@�C���o��(A-3)
      -- ===============================
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
--
      --�o�͕�����쐬
      lv_op_str :=                          cv_dqu || get_fa_books_info_rec.asset_number           || cv_dqu ;   -- ���Y�ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.tag_number             || cv_dqu ;   -- �����R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.segment1               || cv_dqu ;   -- ��ЃR�[�h
 -- 2014/07/04 ADD START
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.vendor_code            || cv_dqu ;   -- �d����R�[�h
 -- 2014/07/04 ADD END
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.description            || cv_dqu ;   -- �E�v
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.date_placed_in_service || cv_dqu ;   -- ���Ƌ��p��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_fa_books_info_rec.original_cost          || cv_dqu ;   -- �擾���i
--
      -- ===============================
      -- 2.CSV�t�@�C���o��
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP fa_books_info_loop;
--
    -- �Ώۃf�[�^�Ȃ��x��
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcff
                      ,iv_name         => cv_msg_cff_00062
                     );
      ov_errbuf  := gv_out_msg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_asset_number                 IN  VARCHAR2     -- 1.���Y�ԍ�
   ,iv_object_code                  IN  VARCHAR2     -- 2.�����R�[�h
   ,iv_segment1                     IN  VARCHAR2     -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2     -- 4.�E�v
   ,iv_date_placed_in_service_from  IN  DATE         -- 5.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  DATE         -- 6.���Ƌ��p�� TO
   ,iv_original_cost_from           IN  VARCHAR2     -- 7.�擾���i FROM
   ,iv_original_cost_to             IN  VARCHAR2     -- 8.�擾���i TO
   ,iv_segment3                     IN  VARCHAR2     -- 9.���Y����
   ,ov_errbuf                       OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_asset_number                => iv_asset_number                -- 1.���Y�ԍ�
     ,iv_object_code                 => iv_object_code                 -- 2.�����R�[�h
     ,iv_segment1                    => iv_segment1                    -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
     ,iv_vendor_code                 => iv_vendor_code                 -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
     ,iv_description                 => iv_description                 -- 4.�E�v
     ,iv_date_placed_in_service_from => iv_date_placed_in_service_from -- 5.���Ƌ��p�� FROM
     ,iv_date_placed_in_service_to   => iv_date_placed_in_service_to   -- 6.���Ƌ��p�� TO
     ,iv_original_cost_from          => iv_original_cost_from          -- 7.�擾���i FROM
     ,iv_original_cost_to            => iv_original_cost_to            -- 8.�擾���i TO
     ,iv_segment3                    => iv_segment3                    -- 9.���Y����
     ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���Y�䒠��񒊏o����(A-2)�A���Y���Z����������X�g�o�͏���(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ��x��
    WHEN no_data_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                          OUT VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                         OUT VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_asset_number                 IN  VARCHAR2     -- 1.���Y�ԍ�
   ,iv_object_code                  IN  VARCHAR2     -- 2.�����R�[�h
   ,iv_segment1                     IN  VARCHAR2     -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN  VARCHAR2     -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
   ,iv_description                  IN  VARCHAR2     -- 4.�E�v
   ,iv_date_placed_in_service_from  IN  VARCHAR2     -- 5.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN  VARCHAR2     -- 6.���Ƌ��p�� TO
   ,iv_original_cost_from           IN  VARCHAR2     -- 7.�擾���i FROM
   ,iv_original_cost_to             IN  VARCHAR2     -- 8.�擾���i TO
   ,iv_segment3                     IN  VARCHAR2     -- 9.���Y����
  )
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_asset_number                => iv_asset_number                    -- 1.���Y�ԍ�
      ,iv_object_code                 => iv_object_code                     -- 2.�����R�[�h
      ,iv_segment1                    => iv_segment1                        -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
      ,iv_vendor_code                 => iv_vendor_code                     -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
      ,iv_description                 => iv_description                     -- 4.�E�v
      ,iv_date_placed_in_service_from => TO_DATE(iv_date_placed_in_service_from,cv_format_std)
                                                                            -- 5.���Ƌ��p�� FROM
      ,iv_date_placed_in_service_to   => TO_DATE(iv_date_placed_in_service_to,cv_format_std)
                                                                            -- 6.���Ƌ��p�� TO
      ,iv_original_cost_from          => iv_original_cost_from              -- 7.�擾���i FROM
      ,iv_original_cost_to            => iv_original_cost_to                -- 8.�擾���i TO
      ,iv_segment3                    => iv_segment3                        -- 9.���Y����
      ,ov_errbuf                      => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                     => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                      => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_cff_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_msg_cff_90004;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_msg_cff_90005;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_msg_cff_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error)
    THEN
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
END XXCFF017A06C;
/
