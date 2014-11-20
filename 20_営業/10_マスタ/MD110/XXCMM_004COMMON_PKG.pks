CREATE OR REPLACE PACKAGE      XXCMM_004COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_004common_pkg(spec)
 * Description            : �i�ڊ֘AAPI
 * MD.070                 : MD070_IPO_XXCMM_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  put_message              ���b�Z�[�W�o��
 *  proc_opmcost_ref         OPM�������f����
 *  proc_opmitem_categ_ref   OPM�i�ڃJ�e�S���������f����
 *  del_opmitem_categ        OPM�i�ڃJ�e�S�������폜����
 *  proc_discitem_categ_ref  Disc�i�ڃJ�e�S���������f����
 *  del_discitem_categ       Disc�i�ڃJ�e�S�������폜����
 *  proc_uom_class_ref       �P�ʊ��Z���f����
 *  proc_conc_request        �R���J�����g���s(+���s�҂�)
 *  ins_opm_item             OPM�i�ړo�^����
 *  upd_opm_item             OPM�i�ڍX�V����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Yoshikawa      �V�K�쐬
 *  2009/04/10    1.2   H.Yoshikawa      ��QT1_0215 �Ή�(chk_single_byte ���폜)
 *
 *****************************************************************************************/
--
  --==============================================
  -- �Œ�l
  --==============================================
  -- �i�ڃX�e�[�^�X
  cn_itm_status_num_tmp        CONSTANT NUMBER       := 10;                         -- ���̔�
  cn_itm_status_pre_reg        CONSTANT NUMBER       := 20;                         -- ���o�^
  cn_itm_status_regist         CONSTANT NUMBER       := 30;                         -- �{�o�^
  cn_itm_status_no_sch         CONSTANT NUMBER       := 40;                         -- �p
  cn_itm_status_trn_only       CONSTANT NUMBER       := 50;                         -- �c�f
  cn_itm_status_no_use         CONSTANT NUMBER       := 60;                         -- �c
  --
  -- �W�������ݒ�p�R���X�^���g�l
  cv_whse_code                 CONSTANT VARCHAR2(3)  := '000';                      -- �q��
  cv_cost_mthd_code            CONSTANT VARCHAR2(4)  := 'STDU';                     -- �������@
  cv_cost_analysis_code        CONSTANT VARCHAR2(4)  := '0000';                     -- ���̓R�[�h
  --
  -- �W�������R���|�[�l���g�敪��
  cv_cost_cmpnt_01gen          CONSTANT VARCHAR2(5)  := '01GEN';                    -- ����
  cv_cost_cmpnt_02sai          CONSTANT VARCHAR2(5)  := '02SAI';                    -- �Đ���
  cv_cost_cmpnt_03szi          CONSTANT VARCHAR2(5)  := '03SZI';                    -- ���ޔ�
  cv_cost_cmpnt_04hou          CONSTANT VARCHAR2(5)  := '04HOU';                    -- ���
  cv_cost_cmpnt_05gai          CONSTANT VARCHAR2(5)  := '05GAI';                    -- �O���Ǘ���
  cv_cost_cmpnt_06hkn          CONSTANT VARCHAR2(5)  := '06HKN';                    -- �ۊǔ�
  cv_cost_cmpnt_07kei          CONSTANT VARCHAR2(5)  := '07KEI';                    -- ���̑��o��
  --
  -- �t�@�C���A�b�v���[�h�`�F�b�N�֘A
  cv_lookup_type_upload_obj    CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';   -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_null_ok                   CONSTANT VARCHAR2(10) := 'NULL_OK';                  -- �C�Ӎ���
  cv_null_ng                   CONSTANT VARCHAR2(10) := 'NULL_NG';                  -- �K�{����
  cv_varchar                   CONSTANT VARCHAR2(10) := 'VARCHAR2';                 -- ������
  cv_number                    CONSTANT VARCHAR2(10) := 'NUMBER';                   -- ���l
  cv_date                      CONSTANT VARCHAR2(10) := 'DATE';                     -- ���t
  cv_varchar_cd                CONSTANT VARCHAR2(1)  := '0';                        -- �����񍀖�
  cv_number_cd                 CONSTANT VARCHAR2(1)  := '1';                        -- ���l����
  cv_date_cd                   CONSTANT VARCHAR2(1)  := '2';                        -- ���t����
  cv_not_null                  CONSTANT VARCHAR2(1)  := '1';                        -- �K�{
  --
  -- �i�ڃJ�e�S���Z�b�g��
  cv_categ_set_seisakugun      CONSTANT VARCHAR2(20) := '����Q�R�[�h';             -- ����Q
  cv_categ_set_hon_prod        CONSTANT VARCHAR2(20) := '�{�Џ��i�敪';             -- �{�Џ��i�敪
  cv_categ_set_item_prod       CONSTANT VARCHAR2(20) := '���i���i�敪';             -- ���i���i�敪
  --
  -- ���t����
  cv_date_fmt_ymd              CONSTANT VARCHAR2(10) := 'YYYYMMDD';                 -- YYYYMMDD
  cv_date_fmt_std              CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';               -- YYYY/MM/DD
  cv_date_fmt_dt_ymdhms        CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';         -- YYYYMMDDHH24MISS
  cv_date_fmt_dt_std           CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';    -- YYYY/MM/DD HH24:MI:SS
  --
  --==============================================
  -- ���R�[�h�^�C�v
  --==============================================
  -- �����i�w�b�_�j���f�p���R�[�h�^�C�v
  TYPE opm_cost_header_rtype IS RECORD
  ( calendar_code      cm_cmpt_dtl.calendar_code%TYPE          -- �J�����_�R�[�h�i�K�{�j
   ,period_code        cm_cmpt_dtl.period_code%TYPE            -- ���ԃR�[�h�i�K�{�j
   ,item_id            ic_item_mst_b.item_id%TYPE              -- OPM�i��ID�i�K�{�j
  );
  --
  -- �����i���ׁj���f�p���R�[�h�^�C�v
  TYPE opm_cost_dist_rtype IS RECORD
  ( cmpntcost_id       cm_cmpt_dtl.cmpntcost_id%TYPE           -- OPM����ID�i�X�V���݂̂Ɏg�p�\�B�ݒ肵�Ȃ��Ă��R���|�[�l���gID���ݒ肳��Ă���Α��v�j
   ,cost_cmpntcls_id   cm_cmpt_mst_b.cost_cmpntcls_id%TYPE     -- �R���|�[�l���gID�i�o�^�E�X�V�ǂ�����K�{�j
   ,cmpnt_cost         cm_cmpt_dtl.cmpnt_cost%TYPE             -- �����i�K�{�j
  );
  --
  -- OPM�i�ڃJ�e�S�������p���R�[�h�^�C�v
  TYPE opmitem_category_rtype IS RECORD
  ( item_id            ic_item_mst_b.item_id%TYPE              -- OPM�i��ID
   ,category_set_id    mtl_category_sets.category_set_id%TYPE  -- �J�e�S���Z�b�gID
   ,category_id        mtl_categories.category_id%TYPE         -- �J�e�S��ID
  );
  -- Disc�i�ڃJ�e�S�������p���R�[�h�^�C�v
  TYPE discitem_category_rtype IS RECORD
  ( inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE  -- Disc�i��ID
   ,category_set_id    mtl_category_sets.category_set_id%TYPE     -- �J�e�S���Z�b�gID
   ,category_id        mtl_categories.category_id%TYPE            -- �J�e�S��ID
  );
  --
  -- �敪�Ԋ��Z�p���R�[�h�^�C�v
  TYPE uom_class_conv_rtype IS RECORD
  ( inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE       -- Disc�i��ID
   ,from_uom_code      mtl_uom_class_conversions.from_uom_code%TYPE    -- �P�ʃR�[�h�i���Z���j Disc�i�ڂ̊�P��
   ,to_uom_code        mtl_uom_class_conversions.to_uom_code%TYPE      -- �P�ʃR�[�h�i���Z��j
   ,conversion_rate    mtl_uom_class_conversions.conversion_rate%TYPE  -- ���Z���[�g�i���萔�j
  );
  --
  -- �R���J�����g�p�����[�^ ���R�[�h�^�C�v
  TYPE conc_argument_rtype IS RECORD
  ( argument           VARCHAR2(100)    -- �p�����[�^
  );
  --
  --==============================================
  -- �e�[�u���^�C�v
  --==============================================
  -- �����i���ׁj���f�p�e�[�u���^�C�v
  TYPE opm_cost_dist_ttype IS TABLE OF opm_cost_dist_rtype INDEX BY BINARY_INTEGER;
  -- 
  -- �R���J�����g�p�����[�^ �e�[�u���^�C�v
  TYPE conc_argument_ttype IS TABLE OF conc_argument_rtype INDEX BY BINARY_INTEGER;
  -- 
  /**********************************************************************************
   * Procedure Name   : put_message
   * Description      : ���b�Z�[�W�o��
   ***********************************************************************************/
  PROCEDURE put_message(
    iv_message_buff   IN       VARCHAR2                                        -- �o�̓��b�Z�[�W
   ,iv_output_div     IN       VARCHAR2 DEFAULT FND_FILE.OUTPUT                -- �o�͋敪
   ,ov_errbuf         OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode        OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg         OUT      VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  /**********************************************************************************
   * Procedure Name   : ins_opmitem_categ
   * Description      : OPM�������f����
   **********************************************************************************/
  PROCEDURE proc_opmcost_ref(
    i_cost_header_rec   IN         opm_cost_header_rtype   -- �����w�b�_
   ,i_cost_dist_tab     IN         opm_cost_dist_ttype     -- ��������
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_opmitem_categ_ref
   * Description      : OPM�i�ڃJ�e�S�������o�^����
   **********************************************************************************/
  PROCEDURE proc_opmitem_categ_ref(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- �i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : del_opmitem_categ
   * Description      : OPM�i�ڃJ�e�S�������폜����
   **********************************************************************************/
  PROCEDURE del_opmitem_categ(
    i_item_category_rec IN         opmitem_category_rtype
                                                      -- �i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_discitem_categ_ref
   * Description      : Disc�i�ڃJ�e�S�������o�^����
   **********************************************************************************/
  PROCEDURE proc_discitem_categ_ref(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : del_discitem_categ
   * Description      : Disc�i�ڃJ�e�S�������폜����
   **********************************************************************************/
  PROCEDURE del_discitem_categ(
    i_item_category_rec IN         discitem_category_rtype
                                                      -- Disc�i�ڃJ�e�S���������R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_uom_class_ref
   * Description      : �P�ʊ��Z���f����
   **********************************************************************************/
  PROCEDURE proc_uom_class_ref(
    i_uom_class_conv_rec IN        uom_class_conv_rtype
                                                      -- �敪�Ԋ��Z���f�p���R�[�h�^�C�v
   ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : proc_conc_request
   * Description      : �R���J�����g���s
   **********************************************************************************/
  PROCEDURE proc_conc_request(
    iv_appl_short_name  IN         VARCHAR2                 -- 1.�A�v���P�[�V�����Z�k���y�K�{�z
   ,iv_program          IN         VARCHAR2                 -- 2.�R���J�����g�v���O�����Z�k���y�K�{�z
   ,iv_description      IN         VARCHAR2 DEFAULT NULL    -- 3.�E�v�y�w��s�v�z
   ,iv_start_time       IN         VARCHAR2 DEFAULT NULL    -- 4.�v���J�n����(DD-MON-YY HH24:MI[:SS])�y�w��s�v�z
   ,ib_sub_request      IN         BOOLEAN  DEFAULT FALSE   -- 5.�T�u���N�G�X�g�y�w��s�v�z
   ,i_argument_tab      IN         conc_argument_ttype      -- 6.�R���J�����g�p�����[�^�y�C�Ӂz
   ,iv_wait_flag        IN         VARCHAR2 DEFAULT 'Y'     -- 7.�R���J�����g���s�҂��t���O
   ,on_request_id       OUT        NUMBER                   -- 8.�v��ID
   ,ov_errbuf           OUT NOCOPY VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : ins_opm_item
   * Description      : OPM�i�ړo�^����
   **********************************************************************************/
  PROCEDURE ins_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM�i�ڃ��R�[�h�^�C�v
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
  /**********************************************************************************
   * Procedure Name   : upd_opm_item
   * Description      : OPM�i�ڍX�V����
   **********************************************************************************/
  PROCEDURE upd_opm_item(
    i_opm_item_rec      IN         ic_item_mst_b%ROWTYPE,  -- OPM�i�ڃ��R�[�h�^�C�v
    ov_errbuf           OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  --
-- Ver1.2  2009/04/10  Del  H.Yoshikawa  ��QT1_0215 �Ή�
--  /**********************************************************************************
--   * Function Name    : chk_single_byte
--   * Description      : ���p�`�F�b�N
--   **********************************************************************************/
--  FUNCTION chk_single_byte(
--    iv_chk_char IN VARCHAR2             --�`�F�b�N�Ώە�����
--  )
--  RETURN BOOLEAN;
--  --
----ito->20090202 TEST
--  --�Ɩ����t�擾�֐�
--  FUNCTION get_process_date
--    RETURN DATE;
-- End
--
END XXCMM_004COMMON_PKG;
/
