CREATE OR REPLACE
PACKAGE BODY xxwip230002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip230002c(body)
 * Description      : ���Y���[�@�\�i���Y����j
 * MD.050/070       : ���Y���[�@�\�i���Y����jIssue1.0  (T_MD050_BPO_230)
 *                    ���Y���[�@�\�i���Y����j          (T_MD070_BPO_23B)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  validate_date_format           PROCEDURE  : ���t�t�H�[�}�b�g�`�F�b�N�֐�
 *  fnc_conv_xml                   FUNCTION   : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml_data               PROCEDURE  : �w�l�k�o�͏���
 *  prc_get_busho_data             PROCEDURE  : �������擾
 *  prc_get_mei_title_data         PROCEDURE  : ���׃^�C�g���擾
 *  prc_create_xml_data            PROCEDURE  : �w�l�k�f�[�^�쐬
 *  prc_create_zeroken_xml_data    PROCEDURE  : �擾�����O�����w�l�k�f�[�^�쐬
 *  prc_get_head_data              PROCEDURE  : �w�b�_�[���擾
 *  prc_get_tonyu_data             PROCEDURE  : ����-������񒊏o
 *  prc_get_reinyu_tonyu_data      PROCEDURE  : ����-�ߓ��i�������j��񒊏o����
 *  prc_get_fsanbutu_data          PROCEDURE  : ����-���Y����񒊏o����
 *  prc_get_utikomi_data           PROCEDURE  : ����-�ō���񒊏o����
 *  prc_get_reinyu_utikomi_data    PROCEDURE  : ����-�ߓ��i�ō����j��񒊏o����
 *  prc_get_tonyu_sizai_data       PROCEDURE  : ����-�������ޏ�񒊏o����
 *  prc_get_reinyu_sizai_data      PROCEDURE  : ����-�ߓ����ޏ�񒊏o����
 *  prc_get_seizou_furyo_data      PROCEDURE  : ����-�����s�Ǐ�񒊏o����
 *  prc_get_gyousha_furyo_data     PROCEDURE  : ����-�Ǝҕs�Ǐ�񒊏o����
 *  prc_check_param_data           PROCEDURE  : �p�����[�^�`�F�b�N����
 *  submain                        PROCEDURE  : ���C�������v���V�[�W��
 *  main                           PROCEDURE  : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/02/06    1.0   Ryouhei Fujii       �V�K�쐬
 *  2008/05/20    1.1   Yusuke  Tabata      �����ύX�v��(Seq95)���t�^�p�����[�^�^�ϊ��Ή�
 *  2008/05/29    1.2   Ryouhei Fujii       �����e�X�g�s��Ή��@NET���Z�p�^�[����Q
 *  2008/06/04    1.3   Daisuke Nihei       �����e�X�g�s��Ή��@�؁^�v���v�Z���s���Ή�
 *                                          �����e�X�g�s��Ή��@�p�[�Z���g�v�Z���s���Ή�
 *  2008/07/02    1.4   Satoshi Yunba       �֑������Ή�
 *  2008/10/28    1.5   Daisuke  Nihei      T_TE080_BPO_230 No15�Ή� ���͓����̌�������쐬������X�V���ɕύX����
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- �p�b�P�[�W��
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWIP230002' ;
--
  -- ���[ID
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWIP230002T' ;                      -- ���[ID
--
  -- ���t�t�H�[�}�b�g
  gv_date_format1               CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';              -- �N���������b
  gv_date_format2               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD HH24:MI';                 -- �N��������
  gv_date_format3               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                         -- �N����
--
  -- ���l�t�H�[�}�b�g
  gv_num_format1               CONSTANT VARCHAR2(15) := 'FM999999990D000';      -- 99999999Z.ZZZ
  gv_num_format2               CONSTANT VARCHAR2(9)  := 'FM990D000';            -- 99Z.ZZZ
  gv_num_format3               CONSTANT VARCHAR2(8)  := 'FM990D00';             -- 99Z.ZZ
--
  /*���׃^�C�g���萔*/
  -- ���׍s�Œ�^�C�g��
  gv_title_header               CONSTANT VARCHAR2(2)  := '��';            -- �^�C�g���^�C�g���ҏW���̐擪�p
  -- �������חp
  gv_tonyu_title                CONSTANT VARCHAR2(10) := '�����@����';    -- �ʏ퓊���i�^�C�g��
  gv_shinkansen_title_tonyu     CONSTANT VARCHAR2(10) := '������';        -- �V�ʐ����C���������i�^�C�g��
  -- �ߓ����חp
  gv_reinyu_title               CONSTANT VARCHAR2(10) := '���߁@����';    -- �ʏ퓊�ߓ��i�^�C�g��
  gv_shinkansen_title_reinyu    CONSTANT VARCHAR2(10) := '�ߓ���';        -- �V�ʐ����C�����ߓ��i�^�C�g��
  -- ���Y���p
  gv_fukusanbutu_title          CONSTANT VARCHAR2(10) := '�����Y����';    -- ���Y���^�C�g��
  -- �ō��p
  gv_utikomi_title              CONSTANT VARCHAR2(10) := '���Ł@����';
  -- ���ރ^�C�g��
  gv_sizai_title_tounyu         CONSTANT VARCHAR2(12) := '���������ށ�';  -- ��������
  gv_sizai_title_reinyu         CONSTANT VARCHAR2(12) := '���ߓ����ށ�';  -- �ߓ�����
  gv_sizai_title_seizofuryo     CONSTANT VARCHAR2(12) := '�������s�ǁ�';  -- �����s��
  gv_sizai_title_gyoshafuryo    CONSTANT VARCHAR2(12) := '���Ǝҕs�ǁ�';  -- �Ǝҕs��
--
  /*���b�Z�[�W�n�萔*/
  -- �^�C�g���擾�G���[���b�Z�[�W
  gv_err_mei_title_no_data      CONSTANT VARCHAR2(100) := '���������̂��擾�ł��܂���ł����B';
--
  gv_err_make_date_from         CONSTANT VARCHAR2(20) := '���Y���iFROM�j';         -- ���Y���iFROM�j
  gv_err_make_date_to           CONSTANT VARCHAR2(20) := '���Y���iTO�j';           -- ���Y���iTO�j
  gv_err_input_date_from        CONSTANT VARCHAR2(20) := '���͓����iFROM�j';       -- ���͓����iFROM�j
  gv_err_input_date_to          CONSTANT VARCHAR2(20) := '���͓����iTO�j';         -- ���͓����iTO�j
  -- ���b�Z�[�W�A�v���P�[�V����
  gc_application_cmn            CONSTANT fnd_application.application_short_name%TYPE  := 'XXCMN' ;
  gc_application_wip            CONSTANT fnd_application.application_short_name%TYPE  := 'XXWIP' ;
  -- �g�[�N��
  gv_tkn_date                   CONSTANT VARCHAR2(10) := 'DATE';
  gv_tkn_param1                 CONSTANT VARCHAR2(10) := 'PARAM1';
  gv_tkn_param2                 CONSTANT VARCHAR2(10) := 'PARAM2';
  gv_tkn_item                   CONSTANT VARCHAR2(10) := 'ITEM';
  gv_tkn_value                  CONSTANT VARCHAR2(10) := 'VALUE';
--
  -- �uOPM�i�ڃ}�X�^.NET�v�����͎��̃f�t�H���g�l
  gv_net_default_val            CONSTANT NUMBER := NULL;
--
  -- �Ɩ��X�e�[�^�X
  gv_status_comp                CONSTANT gme_batch_header.attribute4%TYPE := '7';                     -- ����
--
  -- ���Y�����ڍ׃��C���^�C�v
  gv_line_type_kbn_genryou      CONSTANT gme_material_details.line_type%TYPE := -1;       -- ����
  gv_line_type_kbn_seizouhin    CONSTANT gme_material_details.line_type%TYPE := 1;        -- �����i
  gv_line_type_kbn_fukusanbutu  CONSTANT gme_material_details.line_type%TYPE := 2;        -- ���Y��
--
  -- LOOKUP�^�C�v��
  gv_lookup_type_den_kbn        CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L03';     -- �`�[�敪
  gv_lookup_type_knri_bsho      CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L10';     -- ���ъǗ�����
  gv_lookup_type_item_type      CONSTANT xxcmn_lookup_values_v.lookup_type%TYPE := 'XXCMN_L08';     -- �^�C�v
--
  -- �i�ڃJ�e�S���Z�b�g����
  gv_item_cat_name_item_kbn     CONSTANT xxcmn_item_categories_v.category_set_name%TYPE := '�i�ڋ敪';
--
  -- �i�ڋ敪
  gv_hinmoku_kbn_genryou        CONSTANT xxcmn_item_categories3_v.item_class_code%TYPE := '1';     -- ����
  gv_hinmoku_kbn_sizai          CONSTANT xxcmn_item_categories3_v.item_class_code%TYPE := '2';     -- ����
  gv_hinmoku_kbn_hanseihin      CONSTANT xxcmn_item_categories3_v.item_class_code%TYPE := '4';     -- �����i
  gv_hinmoku_kbn_seihin         CONSTANT xxcmn_item_categories3_v.item_class_code%TYPE := '5';     -- ���i
--
  -- �\��敪
  gv_yotei_kbn_tonyu            CONSTANT xxwip_material_detail.plan_type%TYPE := '4';              -- ����
--
  -- �ō��敪
  gv_utikomi_kbn_utikomi        CONSTANT gme_material_details.attribute5%TYPE := 'Y';
--
  -- �ۗ��g���������t���O
  gv_comp_flag                  CONSTANT ic_tran_pnd.completed_ind%TYPE := 1;    -- ����
--
  -- �Œ�P��
  gv_unit_siage                 CONSTANT xxcmn_item_mst_v.item_um%TYPE := 'kg';  -- �d�㐔�P��
  gv_unit_kirikeikomi           CONSTANT xxcmn_item_mst_v.item_um%TYPE := 'kg';  -- ��/�v���P��
--
--
  -- �f�t�H���g�������敪
  gv_tounyuguchi_kbn_default    CONSTANT gme_material_details.attribute8%TYPE := 'XXXXXX';
--
-- �ǉ� START 2008/05/20 YTabata
  gv_min_date_char              CONSTANT VARCHAR2(10) := '1900/01/01' ;    -- �ŏ����t
  gv_max_date_char              CONSTANT VARCHAR2(10) := '4712/12/31' ;    -- �ő���t
-- �ǉ� END 2008/05/20 YTabata
-- 2008/10/28 v1.7 D.Nihei ADD START ������Q#499
  gv_doc_type_prod              CONSTANT VARCHAR2(4)   := 'PROD';                                  -- PROD (���Y)
-- 2008/10/28 v1.7 D.Nihei ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE type_param_rec IS RECORD (
      iv_den_kbn          gmd_routings_vl.attribute13%TYPE              -- �`�[�敪
     ,iv_plant            gme_batch_header.plant_code%TYPE              -- �v�����g�R�[�h
     ,iv_line_no          gmd_routings_vl.routing_no%TYPE               -- ���C��No
     ,id_make_date_from   gme_batch_header.plan_start_date%TYPE         -- ���Y��(FROM)
     ,id_make_date_to     gme_batch_header.plan_start_date%TYPE         -- ���Y��(TO)
     ,id_tehai_no_from    gme_batch_header.batch_no%TYPE                -- ��zNo(FROM)
     ,id_tehai_no_to      gme_batch_header.batch_no%TYPE                -- ��zNo(TO)
     ,iv_hinmoku_cd       xxcmn_item_mst2_v.item_no%TYPE                -- �i�ڃR�[�h
-- 2008/10/28 v1.7 D.Nihei MOD START
--     ,id_input_date_from  gme_batch_header.creation_date%TYPE           -- ���͓���(FROM)
--     ,id_input_date_to    gme_batch_header.creation_date%TYPE           -- ���͓���(TO)
     ,id_input_date_from  gme_batch_header.last_update_date%TYPE           -- ���͓���(FROM)
     ,id_input_date_to    gme_batch_header.last_update_date%TYPE           -- ���͓���(TO)
-- 2008/10/28 v1.7 D.Nihei MOD END
    ) ;
--
  -- �w�b�_�[�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_head_data_rec IS RECORD (
       l_batch_id         gme_batch_header.batch_id%TYPE              -- ���Y�o�b�`�w�b�_.�o�b�`ID
      ,l_last_updated_by  gme_batch_header.last_updated_by%TYPE       -- ���Y�o�b�`�w�b�_.�ŏI�X�V��ID
      ,l_shinkansen_kbn   gmd_routings_vl.attribute17%TYPE            -- �H���}�X�^VIEW.DFF17�i�V�ʐ��敪�j
      ,l_item_id          gme_material_details.item_id%TYPE           -- ���Y�����ڍ�.�i��ID
      ,l_item_unit        xxcmn_item_mst2_v.item_um%TYPE              -- OPM�i�ڏ��VIEW2.�P��
      ,l_net              NUMBER                                      -- OPM�i�ڏ��VIEW2.NET(NULL���̑Ή�����)
-- Add 2008/05/29
      ,l_item_class       xxcmn_item_categories2_v.segment1%TYPE      -- �i�ڋ敪
-- Add 2008/05/29
      ,l_tehai_no         gme_batch_header.batch_no%TYPE              -- ���Y�o�b�`�w�b�_.�o�b�`NO
      ,l_den_kbn          xxcmn_lookup_values_v.meaning%TYPE          -- �Q�ƃR�[�h.�E�v
      ,l_knri_bsho        xxcmn_lookup_values_v.meaning%TYPE          -- �Q�ƃR�[�h.�E�v
      ,l_hinmk_cd         xxcmn_item_mst2_v.item_no%TYPE              -- OPM�i�ڏ��VIEW2.�i�ڃR�[�h
      ,l_hinmk_nm         xxcmn_item_mst2_v.item_desc1%TYPE           -- OPM�i�ڏ��VIEW2.�E�v
      ,l_line_no          gmd_routings_vl.routing_no%TYPE             -- �H���}�X�^VIEW.�H��NO
      ,l_line_nm          gmd_routings_vl.routing_desc%TYPE           -- �H���}�X�^VIEW.�H���E�v
      ,l_set_cd           gmd_routings_vl.attribute9%TYPE             -- �H���}�X�^VIEW.DFF9�i�[�i�ꏊ�R�[�h�j
      ,l_set_nm           xxcmn_item_locations_v.description%TYPE     -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɖ�
      ,l_make_start_date  DATE                                        -- ���Y�����ڍ�.DFF11(���Y��)
      ,l_make_end_date    DATE                                        -- ���Y�����ڍ�.DFF11(���Y��)
      ,l_shoumikigen      DATE                                        -- ���Y�����ڍ�.DFF10(�ܖ�������)
      ,l_item_type        xxcmn_lookup_values_v.meaning%TYPE          -- �Q�ƃR�[�h.�E�v
      ,l_item_rank1       gme_material_details.attribute2%TYPE        -- ���Y�����ڍ�.DFF2(�����N1)
      ,l_item_rank2       gme_material_details.attribute3%TYPE        -- ���Y�����ڍ�.DFF3(�����N2)
      ,l_item_tekiyo      gme_material_details.attribute4%TYPE        -- ���Y�����ڍ�.DFF4(�E�v)
      ,l_lot_no           ic_lots_mst.lot_no%TYPE                     -- OPM���b�g�}�X�^.���b�gNO
      ,l_move_cd          gme_material_details.attribute12%TYPE       -- ���Y�����ڍ�.DFF12(�ړ��ꏊ�R�[�h)
      ,l_move_nm          xxcmn_item_locations_v.description%TYPE     -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɖ�
      ,l_stock_num        gme_material_details.attribute6%TYPE        -- ���Y�����ڍ�.DFF6(�݌ɓ���)
      ,l_dekidaka         NUMBER                                      -- ���Y�����ڍ�.���ѐ��ʂ̊��Z����
    ) ;
  TYPE type_head_data_tbl IS TABLE OF type_head_data_rec INDEX BY PLS_INTEGER ;
--
  -- ����-�����f�[�^/�ߓ��i�����j�f�[�^/���Y���f�[�^/�ō��f�[�^/�ߓ��i�ō����j�f�[�^
  -- �������ރf�[�^/�ߓ����ރf�[�^/�����s�ǃf�[�^/�Ǝҕs�ǃf�[�^
  -- �i�[�p���R�[�h�ϐ�
  TYPE type_tounyu_data_rec IS RECORD 
    (
      l_material_detail_id    gme_material_details.material_detail_id%TYPE  -- ���Y�����ڍ�ID
     ,l_tounyuguchi_kbn       gme_material_details.attribute8%TYPE          -- �������敪
     ,l_hinmk_cd              xxcmn_item_mst_v.item_no%TYPE                 -- �i�ڃR�[�h
     ,l_hinmk_nm              xxcmn_item_mst_v.item_short_name%TYPE         -- �i���E����
     ,l_lot_no                ic_lots_mst.lot_no%TYPE                       -- ���b�gNo
     ,l_make_date             DATE                                          -- �����N����
     ,l_stock                 NUMBER                                        -- �݌ɓ���
     ,l_total                 xxwip_material_detail.invested_qty%TYPE       -- ������
     ,l_unit                  xxcmn_item_mst_v.item_um%TYPE                 -- �P��
    ) ;
  TYPE type_tounyu_data_tbl IS TABLE OF type_tounyu_data_rec INDEX BY BINARY_INTEGER ;
--
  -- �������i�[�p���R�[�h�ϐ�
  TYPE rec_busho_data  IS RECORD 
    (
      yubin_no   xxcmn_locations_all.zip%TYPE               -- �X�֔ԍ�
     ,address    xxcmn_locations_all.address_line1%TYPE     -- �Z��
     ,tel        xxcmn_locations_all.phone%TYPE             -- �d�b�ԍ�
     ,fax        xxcmn_locations_all.fax%TYPE               -- FAX�ԍ�
     ,busho_nm   xxcmn_locations_all.location_name%TYPE     -- ��������
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
--
--
  /**********************************************************************************
   * Procedure Name   : validate_date_format
   * Description      : ���t�t�H�[�}�b�g�`�F�b�N�֐�
   ***********************************************************************************/
  PROCEDURE validate_date_format
    (
      iv_validate_date    IN         VARCHAR2       -- �`�F�b�N�Ώۓ��t�i�����j
     ,iv_err_item_val     IN         VARCHAR2       -- �G���[���ږ���
     ,iv_date_format      IN         VARCHAR2       -- �ϊ��t�H�[�}�b�g
     ,od_change_date      OUT NOCOPY DATE           -- �ϊ�����t
     ,ov_errbuf           OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_date_format'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���E��O���� ***
    date_format_expt     EXCEPTION ;     -- ���t�t�H�[�}�b�g�s����O
    -- *** ���[�J���ϐ� ***
    lv_validate_date_tmp VARCHAR2(20) DEFAULT NULL ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �w��t�H�[�}�b�g�ւ̕ϊ�
-- �ύX START 2008/05/20 YTabata
/**
    od_change_date := FND_DATE.STRING_TO_DATE(iv_validate_date
                                             ,iv_date_format) ;
--
    IF (od_change_date IS NULL) THEN
      -- ���t�̕ϊ��G���[��
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,iv_err_item_val
                                            ,gv_tkn_value
                                            ,iv_validate_date) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
--
**/
    BEGIN
--
      lv_validate_date_tmp := TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_validate_date),gv_date_format1) ;
--
    EXCEPTION
--
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        RAISE date_format_expt ;
    END ;
    -- �w��t�H�[�}�b�g�ւ̕ϊ�
    od_change_date := FND_DATE.STRING_TO_DATE(lv_validate_date_tmp
                                             ,iv_date_format) ;
--
  EXCEPTION
--
    WHEN date_format_expt THEN
      -- ���t�̕ϊ��G���[��
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,iv_err_item_val
                                            ,gv_tkn_value
                                            ,iv_validate_date) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
-- �ύX END 2008/05/20 YTabata
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_date_format ;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : �w�l�k�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT NOCOPY VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT NOCOPY VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT NOCOPY VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================
    -- �w�l�k�o�͏���
    -- ==================================================
    -- �J�n�^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_nippo_info>' ) ;
--
    <<xml_data_table>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := fnc_conv_xml
                        (
                          iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- �I���^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_nippo_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_busho_data
   * Description      : �������擾
   ***********************************************************************************/
  PROCEDURE prc_get_busho_data
    (
      in_last_updated_user   IN         gme_batch_header.last_updated_by%TYPE       -- �ŏI�X�V��ID
     ,or_busho_data          OUT NOCOPY rec_busho_data
     ,ov_errbuf              OUT NOCOPY VARCHAR2                                    --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT NOCOPY VARCHAR2                                    --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT NOCOPY VARCHAR2                                    --    ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_busho_data'; -- �v���O������
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
    lv_busho_cd hr_locations_all.location_code%TYPE;            -- �����R�[�h
-- 
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
      SELECT hla.location_code
      INTO   lv_busho_cd
      FROM   fnd_user              fu
            ,per_all_assignments_f paaf
            ,hr_locations_all      hla
      WHERE  fu.user_id                 = in_last_updated_user
      AND    fu.employee_id             = paaf.person_id
      AND    paaf.location_id           = hla.location_id
      AND    paaf.effective_start_date <= TRUNC(SYSDATE)
      AND    paaf.effective_end_date   >= TRUNC(SYSDATE)
      AND    fu.start_date             <= TRUNC(SYSDATE)
      AND    ((fu.end_date IS NULL) OR (fu.end_date >= TRUNC(SYSDATE)))
      AND    ((hla.inactive_date IS NULL) OR (hla.inactive_date >= TRUNC(SYSDATE)))
      AND    paaf.primary_flag = 'Y'
    ;
--
    IF (lv_busho_cd IS NOT NULL) THEN
      -- =====================================================
      -- �������擾�v���V�[�W���Ăяo��
      -- =====================================================
      xxcmn_common_pkg.get_dept_info
        (
          iv_dept_cd                =>    lv_busho_cd
         ,id_appl_date              =>    NULL
         ,ov_postal_code            =>    or_busho_data.yubin_no
         ,ov_address                =>    or_busho_data.address
         ,ov_tel_num                =>    or_busho_data.tel
         ,ov_fax_num                =>    or_busho_data.fax
         ,ov_dept_formal_name       =>    or_busho_data.busho_nm
         ,ov_errbuf                 =>    lv_errbuf
         ,ov_retcode                =>    lv_retcode
         ,ov_errmsg                 =>    lv_errmsg
        );
--
    END IF;
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      -- �f�[�^���o�s��or�����s�擾��
      NULL;     -- �������Ȃ�
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END prc_get_busho_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_mei_title_data
   * Description      : ���׃^�C�g���擾
   ***********************************************************************************/
  PROCEDURE prc_get_mei_title_data
    (
      in_material_detail_id IN         gme_material_details.material_detail_id%TYPE    -- ���Y�����ڍ�ID
     ,ov_mei_title          OUT NOCOPY VARCHAR2                                        -- ���׃^�C�g��
     ,ov_errbuf             OUT NOCOPY VARCHAR2                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT NOCOPY VARCHAR2                                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT NOCOPY VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_mei_title_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT gov.oprn_desc
    INTO   ov_mei_title
    FROM   gme_batch_steps           gbs,           -- ���Y�o�b�`�X�e�b�v
           gmd_operations_vl         gov,           -- �H���}�X�^�r���[
           gme_batch_step_items      gbsi           -- ���Y�o�b�`�X�e�b�v�i��
    WHERE  gbs.batchstep_id        = gbsi.batchstep_id
    AND    gov.oprn_id             = gbs.oprn_id
    AND    gbsi.material_detail_id = in_material_detail_id
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      -- �f�[�^���o�s��or�����s�擾��
      NULL;     -- �������Ȃ�
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
  END prc_get_mei_title_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param_rec           IN         type_param_rec        -- �p�����[�^��n���p
     ,ir_head_data           IN         type_head_data_rec    -- �擾���R�[�h�i�w�b�_���j
     ,it_tonyu_data          IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�������j
     ,it_reinyu_tonyu_data   IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�ߓ��i�������j���j
     ,it_fukusanbutu_data    IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-���Y�����j
     ,it_utikomi_data        IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�ō����j
     ,it_reinyu_utikomi_data IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�ߓ��i�ō����j���j
     ,it_tonyu_sizai_data    IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�������ޏ��j
     ,it_reinyu_sizai_data   IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�ߓ����ޏ��j
     ,it_seizou_furyo_data   IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�����s�Ǐ��j
     ,it_gyousha_furyo_data  IN         type_tounyu_data_tbl  -- �擾���R�[�h�\�i����-�Ǝҕs�Ǐ��j
     ,id_now_date            IN         DATE                  -- ���ݓ�
     ,ov_errbuf              OUT NOCOPY VARCHAR2              -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode             OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg              OUT NOCOPY VARCHAR2              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �z��J�E���^�ϐ�
    l_cnt                    PLS_INTEGER;
    -- �������
    lr_busho_data            rec_busho_data;
    -- �������敪�u���C�N�p�ϐ�
    lv_tounyuguchi_kbn       gme_material_details.attribute8%TYPE DEFAULT 'ZZZZZZZZZZ';
    -- ���׃^�C�g��
    lv_mei_title             gmd_operations_vl.oprn_desc%TYPE;
    -- �������׃T�}���p�ϐ�
    ln_tounyu_total          NUMBER DEFAULT 0 ;
    -- �ߓ��i�����j���׃T�}���p�ϐ�
    ln_reinyu_tounyu_total   NUMBER DEFAULT 0 ;
    -- ���Y�����׃T�}���p�ϐ�
    ln_fukusanbutu_total     NUMBER DEFAULT 0 ;
    -- �ō����׃T�}���p�ϐ�
    ln_utikomi_total         NUMBER DEFAULT 0 ;
    -- �d�グ��
    ln_siage_total           NUMBER DEFAULT 0;
    -- �؁^�v�����׍��v
    ln_kirikeikomi_total     NUMBER DEFAULT 0;
    -- �ߓ��i�ō��j���׃T�}���p�ϐ�
    ln_reinyu_utikomi_total  NUMBER DEFAULT 0;
-- 2008/10/28 v1.7 D.Nihei ADD START
    ln_invest_total          NUMBER DEFAULT 0;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���Y����f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--=========================================================================
    -- �y�f�[�^�z���[ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- �y�f�[�^�z���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(id_now_date, gv_date_format2);
--
    -- �y�f�[�^�z��zNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tehai_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_tehai_no;
--
    -- �y�f�[�^�z�`�[�敪����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'den_kbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_den_kbn;
--
    -- �y�f�[�^�z���ъǗ���������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'knri_bsho';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_knri_bsho;
--
    -- =====================================================
    -- �������擾����
    -- =====================================================
    prc_get_busho_data(
        in_last_updated_user  =>   ir_head_data.l_last_updated_by
       ,or_busho_data         =>   lr_busho_data
       ,ov_errbuf             =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- �y�f�[�^�z�S����������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.busho_nm;
--
    -- �y�f�[�^�z�����i�i�ڃR�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_hinmk_cd;
--
    -- �y�f�[�^�z�����i�i�ږ���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_hinmk_nm;
--
    -- �y�f�[�^�z���C��No
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_line_no;
--
    -- �y�f�[�^�z���C������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_line_nm;
--
    -- �y�f�[�^�z�[�i�ꏊ�R�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_set_cd;
--
    -- �y�f�[�^�z�[�i�ꏊ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_set_nm;
--
    -- �y�f�[�^�z���Y�J�n��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_start_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_make_start_date,gv_date_format3);
--
    -- �y�f�[�^�z���Y�I����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_end_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_make_end_date,gv_date_format3);
--
    -- �y�f�[�^�z�ܖ�����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'shoumikigen';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_shoumikigen,gv_date_format3);
--
    -- �y�f�[�^�z�^�C�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_type;
--
    -- �y�f�[�^�z�����N�P
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank1';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_rank1;
--
    -- �y�f�[�^�z�����N�Q
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank2';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_rank2;
--
    -- �y�f�[�^�z�E�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_tekiyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_tekiyo;
--
    -- �y�f�[�^�z���b�gNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_lot_no;
--
    -- �y�f�[�^�z�ړ��ꏊ�R�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_move_cd;
--
    -- �y�f�[�^�z�ړ��ꏊ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_move_nm;
--
    -- �y�f�[�^�z�݌ɓ���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_stock_num , gv_num_format2);
--
    -- �y�f�[�^�z�o����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_dekidaka , gv_num_format1);
--
--=========================================================================
    -- -----------------------------------------------------
    -- ���׏��f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- �����i���׃��[�v
    -- -----------------------------------------------------
    <<tonyu_data_loop>>
    FOR l_cnt IN 1..it_tonyu_data.COUNT LOOP
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �����i���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_tonyu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �����i���׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- �����i���׃^�C�g����������
      -- =====================================================
      -- �V�ʐ����C���̏ꍇ
      IF (ir_head_data.l_shinkansen_kbn = 'Y') THEN
        -- �������敪�u���C�N�`�F�b�N
        IF (lv_tounyuguchi_kbn <> it_tonyu_data(l_cnt).l_tounyuguchi_kbn) THEN
          prc_get_mei_title_data(
              in_material_detail_id  =>   it_tonyu_data(l_cnt).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode             =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg              =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            -- �֐��G���[�̏ꍇ�͗�O��
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            -- �^�C�g���擾���o���Ȃ������ꍇ�͗�O��
            lv_errbuf := gv_err_mei_title_no_data;
            lv_errmsg := gv_err_mei_title_no_data;
            RAISE global_process_expt ;
          END IF;
          -- �擾OK�Ȃ�^�C�g���o��
          -- �y�f�[�^�z�����i�^�C�g��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_title_header || lv_mei_title || gv_shinkansen_title_tonyu;
--
          -- �����㌻���R�[�h�l��ێ�
          lv_tounyuguchi_kbn := it_tonyu_data(l_cnt).l_tounyuguchi_kbn;
        ELSE
          -- �O���R�[�h�����ꍇ�́A�����R�[�h�l��ێ�
          lv_tounyuguchi_kbn := it_tonyu_data(l_cnt).l_tounyuguchi_kbn;
--
        END IF;
--
      ELSE
      -- �V�ʐ����C���ȊO�̏ꍇ
        -- ���׏��P���ڂ̏o�͂̏ꍇ
        IF (l_cnt = 1) THEN
          -- �y�f�[�^�z�����i�^�C�g��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_tonyu_title;
        END IF;
--
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_hinmk_cd ;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_hinmk_nm ;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_lot_no ;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- �y�f�[�^�z�݌ɓ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_data(l_cnt).l_total ,gv_num_format1);
      -- �����i���ב����̍��v
      ln_tounyu_total := ln_tounyu_total + it_tonyu_data(l_cnt).l_total ;
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(l_cnt).l_unit ;
--
      -- �y�^�O�z�����i���׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �������׍ŏI�s�̏����̏ꍇ
      IF (l_cnt = it_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �����i���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_tonyu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_data_loop ;
--
--=========================================================================
    -- �������ׂ����݂��Ȃ��ꍇ�́A���v�s���o�͂��Ȃ�
    IF (it_tonyu_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- �����i���׍��v�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z�����i���׍��v��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_tounyu_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- �����i���׍��v�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �ߓ��i���׃��[�v
    -- -----------------------------------------------------
    <<reinyu_tonyu_data_loop>>
    FOR l_cnt IN 1..it_reinyu_tonyu_data.COUNT LOOP
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �ߓ��i�����j�i���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �ߓ��i�����j���׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- �ߓ��i���׃^�C�g����������
      -- =====================================================
      -- �V�ʐ����C���̏ꍇ
      IF (ir_head_data.l_shinkansen_kbn = 'Y') THEN
        -- �������敪�u���C�N�`�F�b�N
        IF (lv_tounyuguchi_kbn <> it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn) THEN
          prc_get_mei_title_data(
              in_material_detail_id  =>   it_reinyu_tonyu_data(l_cnt).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
             ,ov_retcode             =>   lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
             ,ov_errmsg              =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            -- �֐��G���[�̏ꍇ�͗�O��
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            -- �^�C�g���擾���o���Ȃ������ꍇ�͗�O��
            lv_errbuf := gv_err_mei_title_no_data;
            lv_errmsg := gv_err_mei_title_no_data;
            RAISE global_process_expt ;
          END IF;
          -- �擾OK�Ȃ�^�C�g���o��
          -- �y�f�[�^�z�ߓ��i�����j�^�C�g��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_title_header || lv_mei_title || gv_shinkansen_title_reinyu;
--
          -- �����㌻���R�[�h�l��ێ�
          lv_tounyuguchi_kbn := it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn;
        ELSE
          -- �O���R�[�h�����ꍇ�́A�����R�[�h�l��ێ�
          lv_tounyuguchi_kbn := it_reinyu_tonyu_data(l_cnt).l_tounyuguchi_kbn;
--
        END IF;
--
      ELSE
      -- �V�ʐ����C���ȊO�̏ꍇ
        -- ���׏��P���ڂ̏o�͂̏ꍇ
        IF (l_cnt = 1) THEN
          -- �y�f�[�^�z�ߓ��i�����j�^�C�g��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_reinyu_title;
        END IF;
--
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_hinmk_cd ;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_hinmk_nm ;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_lot_no ;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- �y�f�[�^�z�݌ɓ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_tonyu_data(l_cnt).l_total ,gv_num_format1);
      -- �ߓ��i���ב����̍��v
      ln_reinyu_tounyu_total := ln_reinyu_tounyu_total + it_reinyu_tonyu_data(l_cnt).l_total ;
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_tonyu_data(l_cnt).l_unit ;
--
      -- �y�^�O�z�ߓ��i�����j���׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �ߓ��i�����j���׍ŏI�s�̏����̏ꍇ
      IF (l_cnt = it_reinyu_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �ߓ��i�����j���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_tonyu_data_loop ;
--
--=========================================================================
    -- �ߓ����ׂ����݂��Ȃ��ꍇ�́A���v�s���o�͂��Ȃ�
    IF (it_reinyu_tonyu_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- �ߓ��i�����j���׍��v�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z�ߓ��i�����j���׍��v��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_reinyu_tounyu_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- �ߓ��i�����j���׍��v�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
-- 2008/10/28 v1.7 D.Nihei ADD START
    ln_invest_total := NVL(ln_tounyu_total, 0) - NVL(ln_reinyu_tounyu_total, 0);
-- 2008/10/28 v1.7 D.Nihei ADD END
--
--=========================================================================
    -- -----------------------------------------------------
    -- ���Y�����׃��[�v
    -- -----------------------------------------------------
    <<fukusanbutu_data_loop>>
    FOR l_cnt IN 1..it_fukusanbutu_data.COUNT LOOP
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- ���Y�����ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_fsanbutu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- ���Y�����׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_fsanbutu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z���Y���^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fukusanbutu_title;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_hinmk_cd ;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_hinmk_nm ;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_lot_no ;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- �y�f�[�^�z�݌ɓ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_stock ,gv_num_format2);
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_fukusanbutu_data(l_cnt).l_total ,gv_num_format1);
      -- ���Y�����ב����̍��v
      ln_fukusanbutu_total := ln_fukusanbutu_total + it_fukusanbutu_data(l_cnt).l_total ;
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_fukusanbutu_data(l_cnt).l_unit ;
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_percent';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- �i���Y�����^�������i���j�~100�i�����_��3�ʂŎl�̌ܓ��j
-- 2008/10/28 v1.7 D.Nihei ADD START
--      gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                  TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / ln_tounyu_total ) * 100 ) , 2)
--                  TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / (ln_tounyu_total - ln_reinyu_tounyu_total) ) * 100 ) , 2)
---- 2008/06/04 D.Nihei MOD END
--                          ,gv_num_format3);
      IF ( ( NVL(it_fukusanbutu_data(l_cnt).l_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (it_fukusanbutu_data(l_cnt).l_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
      -- �y�^�O�z���Y�����׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_fsanbutu_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- ���Y�����׍ŏI�s�̏����̏ꍇ
      IF (l_cnt = it_fukusanbutu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- ���Y�����ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_fsanbutu_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP fukusanbutu_data_loop ;
--
--=========================================================================
    -- ���Y�����ׂ����݂��Ȃ��ꍇ�́A���v�s���o�͂��Ȃ�
    IF it_fukusanbutu_data.COUNT <> 0 THEN
      -- -----------------------------------------------------
      -- ���Y�����׍��v�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z���Y�����׍��v��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_fukusanbutu_total ,gv_num_format1);
--
      -- �y�f�[�^�z���v����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'fsanbutu_sum_percent';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- �i���Y�����׍��v���^�������i���j�~100�i�����_��3�ʂŎl�̌ܓ��j
-- 2008/10/28 v1.7 D.Nihei ADD START
--      gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                  TO_CHAR( ROUND( ( (ln_fukusanbutu_total / ln_tounyu_total ) * 100 ) , 2)
--                  TO_CHAR( ROUND( ( (ln_fukusanbutu_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 ) , 2)
---- 2008/06/04 D.Nihei MOD END
--                          ,gv_num_format3);
      IF ( ( NVL(ln_fukusanbutu_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_fukusanbutu_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
      -- -----------------------------------------------------
      -- ���Y�����׍��v�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_fsanbutu_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �ō����׃��[�v
    -- -----------------------------------------------------
    <<utikomi_data_loop>>
    FOR l_cnt IN 1..it_utikomi_data.COUNT LOOP
--
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �ō����ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �ō����׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      -- �s�J�n�^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�ō��^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_utikomi_title ;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_lot_no;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_make_date ,gv_date_format3);
--
      -- �y�f�[�^�z�݌ɓ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_stock ,gv_num_format2);
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_utikomi_data(l_cnt).l_total ,gv_num_format1);
      -- �ō����ב����̍��v
      ln_utikomi_total := ln_utikomi_total + it_utikomi_data(l_cnt).l_total ;
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(l_cnt).l_unit;
--
      -- �y�^�O�z�ō����׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �ō����ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP utikomi_data_loop ;
--
--=========================================================================
    -- �ō����ׂ����݂��Ȃ��ꍇ�́A���v�s���o�͂��Ȃ�
    IF (it_utikomi_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- �ō����׍��v�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z�ō����׍��v��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_utikomi_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- �ō����׍��v�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �d�㐔�f�[�^�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_siagesuu_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- �y�f�[�^�z�d�㐔
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- �d�㐔�v�Z
-- Changed 2008/05/29
    -- �i�w�b�_�̊����i�i�ڂ́uNET�v���ځ~�w�b�_�o�����@�^�@1000�j�|�@�ō�����
--    ln_siage_total := ((ir_head_data.l_dekidaka * ir_head_data.l_net) / 1000) - ln_utikomi_total ;
    IF ir_head_data.l_item_class = gv_hinmoku_kbn_seihin THEN
      -- �i�ڋ敪���u���i�v�̎�
      -- �i�w�b�_�̊����i�i�ڂ́uNET�v���ځ~�w�b�_�o�����@�^�@1000�j�|�@�ō�����
      ln_siage_total := ((ir_head_data.l_dekidaka * ir_head_data.l_net) / 1000) - ln_utikomi_total ;
    ELSE
      -- �i�ڋ敪�����u���i�v�̎�
      ln_siage_total := ir_head_data.l_dekidaka  - ln_utikomi_total ;
    END IF;
-- Changed 2008/05/29
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ROUND(ln_siage_total , 3) ,gv_num_format1);
--
    -- �y�f�[�^�z�d�㐔�P��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_unit_siage ;
--
    -- �y�f�[�^�z�d�㐔����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'siagesuu_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- �i�d�㐔�^�������i���j�~100�i�����_��3�ʂŎl�̌ܓ��j
-- 2008/10/28 v1.7 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND(  (ln_siage_total / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND(  (ln_siage_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
--                        ,gv_num_format3);
---- 2008/06/04 D.Nihei MOD END
      IF ( ( NVL(ln_siage_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_siage_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- �d�㐔�f�[�^�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_siagesuu_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- �ߓ��i�ō��j���׃��[�v
    -- -----------------------------------------------------
    <<reinyu_utikomi_data_loop>>
    FOR l_cnt IN 1..it_reinyu_utikomi_data.COUNT LOOP
--
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �ߓ��i�ō��j���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �ߓ��i�ō��j���׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      -- �s�J�n�^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�ߓ��i�ō��j�^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_reinyu_title ;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_lot_no;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_make_date
                                                        ,gv_date_format3);
--
      -- �y�f�[�^�z�݌ɓ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_stock';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_stock
                                                        ,gv_num_format2);
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_utikomi_data(l_cnt).l_total
                                                        ,gv_num_format1);
      -- �ߓ��i�ō��j���ב����̍��v
      ln_reinyu_utikomi_total := ln_reinyu_utikomi_total + it_reinyu_utikomi_data(l_cnt).l_total ;
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_utikomi_data(l_cnt).l_unit;
--
      -- �y�^�O�z�ߓ��i�ō��j���׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_utikomi_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_reinyu_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �ߓ��i�ō��j���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_utikomi_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_utikomi_data_loop ;
--
--=========================================================================
--
    -- �ߓ��i�ō��j���ׂ����݂��Ȃ��ꍇ�́A���v�s���o�͂��Ȃ�
    IF (it_reinyu_utikomi_data.COUNT <> 0) THEN
      -- -----------------------------------------------------
      -- �ߓ��i�ō��j���׍��v�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z�ߓ��i�ō��j���׍��v��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_reinyu_utikomi_total ,gv_num_format1);
--
      -- -----------------------------------------------------
      -- �ߓ��i�ō��j���׍��v�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_utikomi_sum';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �؁^�v�����׃f�[�^�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_kirikeikomi_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- �y�f�[�^�z�؁^�v�����׍��v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- �؁^�v�����׍��v�̌v�Z
    -- �������v�|�i�d�㐔�{���Y���v�j�̒l���Z�b�g
-- 2008/06/04 D.Nihei MOD START
--    ln_kirikeikomi_total := ln_tounyu_total - (ln_siage_total + ln_fukusanbutu_total) ;
    ln_kirikeikomi_total := ln_tounyu_total - (ln_siage_total + ln_fukusanbutu_total) - (ln_reinyu_tounyu_total + ln_reinyu_utikomi_total);
-- 2008/06/04 D.Nihei MOD END
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_kirikeikomi_total ,gv_num_format1);
--
    -- �y�f�[�^�z�؁^�v�����גP��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_unit_kirikeikomi ;
--
    -- �y�f�[�^�z�؁^�v�����׊���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- �؁^�v�����׍��v�@�^�@�������v�@���@100�i�����_��3�ʂŎl�̌ܓ��j�̒l���o��
-- 2008/10/28 v1.7 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value :=
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND( (ln_kirikeikomi_total / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND( (ln_kirikeikomi_total / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
---- 2008/06/04 D.Nihei MOD END
--                        ,gv_num_format3);
      IF ( ( NVL(ln_kirikeikomi_total, 0) = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND( ( (ln_kirikeikomi_total / ln_invest_total ) * 100 ) , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- �؁^�v�����׃f�[�^�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_kirikeikomi_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- �؁^�v�����v�f�[�^�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- �y�f�[�^�z���Y���E�؂�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    -- ���Y���v + �؁^�v�����׍��v���Z�b�g
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ln_fukusanbutu_total + ln_kirikeikomi_total
                                                      ,gv_num_format1);
--
    -- �y�f�[�^�z�؁^�v�����v����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'kirikeikomi_sum_percent';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      -- ���Y���E�؂�v�@�^�@�u�R�v�̓����v�@���@100�i�����_��3�ʂŎl�̌ܓ��j�̒l���o��
-- 2008/10/28 v1.7 D.Nihei ADD START
--    gt_xml_data_table(gl_xml_idx).tag_value := 
---- 2008/06/04 D.Nihei MOD START
----                TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / ln_tounyu_total) * 100 , 2)
--                TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / (ln_tounyu_total - ln_reinyu_tounyu_total)) * 100 , 2)
---- 2008/06/04 D.Nihei MOD END
--                        ,gv_num_format3);
      IF ( ( ln_fukusanbutu_total + ln_kirikeikomi_total = 0 ) OR ( ln_invest_total = 0 ) ) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := 0;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ROUND(((ln_fukusanbutu_total + ln_kirikeikomi_total) / ln_invest_total) * 100 , 2), gv_num_format3);
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD END
--
    -- -----------------------------------------------------
    -- �؁^�v�����v�f�[�^�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_kirikeikomi_sum';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- �o�����f�[�^�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dekidaka_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- �y�f�[�^�z�o������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ir_head_data.l_dekidaka ,gv_num_format1);  -- �w�b�_�Ɠ����l
--
    -- �y�f�[�^�z�o�����P��
    -- ���[������I�ɑ��݂��Ă��邪�A�^�O�o�͂��Ȃ��B
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'dekidaka_unit';
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ir_head_data.l_item_unit ;
--
    -- -----------------------------------------------------
    -- �o�����f�[�^�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dekidaka_mei';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--=========================================================================
    -- -----------------------------------------------------
    -- �������ޖ��׃��[�v
    -- -----------------------------------------------------
    <<tonyu_sizai_data_loop>>
    FOR l_cnt IN 1..it_tonyu_sizai_data.COUNT LOOP
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �������ޖ��ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_tonyu_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �������ޖ��׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_tonyu_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�������ރ^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_tounyu;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_tonyu_sizai_data(l_cnt).l_total ,gv_num_format1);
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_sizai_data(l_cnt).l_unit;
--
      -- �y�^�O�z�������ޖ��׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_tonyu_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_tonyu_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �������ޖ��ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_tonyu_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_sizai_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �ߓ����ޖ��׃��[�v
    -- -----------------------------------------------------
    <<reinyu_sizai_data_loop>>
    FOR l_cnt IN 1..it_reinyu_sizai_data.COUNT LOOP
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �ߓ����ޖ��ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_modori_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �ߓ����ޖ��׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_modori_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�ߓ����ރ^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_reinyu;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_reinyu_sizai_data(l_cnt).l_total ,gv_num_format1);
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'modori_sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_reinyu_sizai_data(l_cnt).l_unit;
--
      -- �y�^�O�z�ߓ����ޖ��׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_modori_sizai_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_reinyu_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �ߓ����ޖ��ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_modori_sizai_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP reinyu_sizai_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �����s�ǎ��ޖ��׃��[�v
    -- -----------------------------------------------------
    <<seizou_furyo_data_loop>>
    FOR l_cnt IN 1..it_seizou_furyo_data.COUNT LOOP
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �����s�ǎ��ޖ��ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_make_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �����s�ǎ��ޖ��׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_make_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�����s�ǎ��ރ^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_seizofuryo;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_seizou_furyo_data(l_cnt).l_total ,gv_num_format1);
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_furyou_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_seizou_furyo_data(l_cnt).l_unit;
--
      -- �y�^�O�z�����s�ǎ��ޖ��׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_make_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_seizou_furyo_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �����s�ǎ��ޖ��ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_make_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP seizou_furyo_data_loop ;
--
--=========================================================================
    -- -----------------------------------------------------
    -- �Ǝҕs�ǎ��ޖ��׃��[�v
    -- -----------------------------------------------------
    <<gyousha_furyo_data_loop>>
    FOR l_cnt IN 1..it_gyousha_furyo_data.COUNT LOOP
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- -----------------------------------------------------
        -- �Ǝҕs�ǎ��ޖ��ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gyosya_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
      -- -----------------------------------------------------
      -- �Ǝҕs�ǎ��ޖ��׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gyosya_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �擪�s�̂ݎ��{
      IF (l_cnt = 1) THEN
        -- �y�f�[�^�z�Ǝҕs�ǎ��ރ^�C�g��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title_gyoshafuryo;
      END IF;
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_hinmk_cd;
--
      -- �y�f�[�^�z�i�ڗ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_hinmk_nm;
--
      -- �y�f�[�^�z����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_gyousha_furyo_data(l_cnt).l_total
                                                        ,gv_num_format1);
--
      -- �y�f�[�^�z�P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gyosya_furyou_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_gyousha_furyo_data(l_cnt).l_unit;
--
      -- �y�^�O�z�Ǝҕs�ǎ��ޖ��׃f�[�^�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gyosya_furyou_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (l_cnt = it_gyousha_furyo_data.COUNT) THEN
        -- -----------------------------------------------------
        -- �Ǝҕs�ǎ��ޖ��ׂf�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gyosya_furyou_mei';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP gyousha_furyo_data_loop ;
--
--=========================================================================
--
    -- =====================================================
    -- ���Y������o�͏I������
    -- =====================================================
    ------------------------------
    -- ���׏��f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���Y����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END prc_create_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : �擾�����O�����w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ir_param          IN         type_param_rec    -- ���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- ���[�^�C�g��
    lv_chohyo_title           VARCHAR2(10);
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �˗���f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ���ׂf�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- ���b�Z�[�W�o�̓^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'message';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,'APP-XXCMN-10122'  ) ;
--
    ------------------------------
    -- �˗���f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_nippo' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END prc_create_zeroken_xml_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_head_data
   * Description      : �w�b�_�[���擾
   ***********************************************************************************/
  PROCEDURE prc_get_head_data
    (
      ir_param         IN         type_param_rec         -- ���̓p�����[�^
     ,ot_head_data     OUT NOCOPY type_head_data_tbl     -- �擾�f�[�^�z��
     ,ov_errbuf        OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W             --# �Œ� #
     ,ov_retcode       OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h               --# �Œ� #
     ,ov_errmsg        OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_head_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           gbh.batch_id                                            AS batch_id         -- ���Y�o�b�`�w�b�_.�o�b�`ID
          ,gbh.last_updated_by                                     AS last_updated_by  -- ���Y�o�b�`�w�b�_.�ŏI�X�V��ID
          ,grv.attribute17                                         AS shinkansen_kbn   -- �H���}�X�^VIEW.DFF17�i�V�ʐ��敪�j
          ,gmd.item_id                                             AS item_id          -- ���Y�����ڍ�.�i��ID
          ,xim2v.item_um                                           AS item_um          -- OPM�i�ڏ��VIEW2.�P��
          ,NVL(TO_NUMBER(xim2v.net) , gv_net_default_val)          AS net              -- OPM�i�ڏ��VIEW2.NET(NULL���̑Ή�����)
-- Add 2008/05/29
          ,xic2v.segment1                                          AS item_class       -- �i�ڋ敪
-- Add 2008/05/29
           --�ȉ��f�[�^�p����
          ,gbh.batch_no                                            AS tehai_no         -- ���Y�o�b�`�w�b�_.�o�b�`NO
          ,xlv1v1.meaning                                          AS den_kbn          -- �Q�ƃR�[�h.�E�v
          ,xlv1v2.meaning                                          AS knri_bsho        -- �Q�ƃR�[�h.�E�v
          ,xim2v.item_no                                           AS hinmk_cd         -- OPM�i�ڏ��VIEW2.�i�ڃR�[�h
          ,xim2v.item_short_name                                   AS hinmk_nm         -- OPM�i�ڏ��VIEW2.�i���E����
          ,grv.routing_no                                          AS line_no          -- �H���}�X�^VIEW.�H��NO
          ,grv.routing_desc                                        AS line_nm          -- �H���}�X�^VIEW.�H���E�v
          ,grv.attribute9                                          AS set_cd           -- �H���}�X�^VIEW.DFF9�i�[�i�ꏊ�R�[�h�j
          ,xil1v1.description                                      AS set_nm           -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɖ�
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                  ,gv_date_format3)                AS make_start_date  -- ���Y�����ڍ�.DFF11(���Y��)
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                  ,gv_date_format3)                AS make_end_date    -- ���Y�����ڍ�.DFF11(���Y��)
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute10 , 1 , 10)
                                  ,gv_date_format3)                AS shoumikigen      -- ���Y�����ڍ�.DFF10(�ܖ�������)
          ,xlv1v3.meaning                                          AS item_type        -- �Q�ƃR�[�h.�E�v
          ,gmd.attribute2                                          AS item_rank1       -- ���Y�����ڍ�.DFF2(�����N1)
          ,gmd.attribute3                                          AS item_rank2       -- ���Y�����ڍ�.DFF3(�����N2)
          ,RTRIM(SUBSTRB(gmd.attribute4 , 1 , 100))                AS item_tekiyo      -- ���Y�����ڍ�.DFF4(�E�v)
          ,ilm.lot_no                                              AS lot_no           -- OPM���b�g�}�X�^.���b�gNO
          ,gmd.attribute12                                         AS move_cd          -- ���Y�����ڍ�.DFF12(�ړ��ꏊ�R�[�h)
          ,xil1v2.description                                      AS move_nm          -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɖ�
          ,gmd.attribute6                                          AS stock_num        -- ���Y�����ڍ�.DFF6(�݌ɓ���)
          ,xxcmn_common_pkg.rcv_ship_conv_qty('2'
                                             ,gmd.item_id
                                             ,gmd.actual_qty)      AS dekidaka         -- ���Y�����ڍ�.���ѐ��ʂ̊��Z����
    --
    BULK COLLECT INTO ot_head_data
    --
    FROM   gme_batch_header           gbh     -- ���Y�o�b�`�w�b�_
          ,gmd_routings_vl            grv     -- �H���}�X�^VIEW
          ,gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxcmn_lookup_values_v      xlv1v1  -- �N�C�b�N�R�[�h���VIEW(�`�[�敪)
          ,xxcmn_lookup_values_v      xlv1v2  -- �N�C�b�N�R�[�h���VIEW(���ъǗ�����)
          ,xxcmn_lookup_values_v      xlv1v3  -- �N�C�b�N�R�[�h���VIEW(�^�C�v)
          ,xxcmn_item_locations_v     xil1v1  -- OPM�ۊǏꏊ���VIEW(�[�i�ꏊ)
          ,xxcmn_item_locations_v     xil1v2  -- OPM�ۊǏꏊ���VIEW(�ړ��ꏊ)
          ,ic_tran_pnd                itp     -- OPM�ۗ��݌Ƀg�����U�N�V����
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst2_v          xim2v   -- OPM�i�ڏ��VIEW2
-- Add 2008/05/29
          , xxcmn_item_categories2_v  xic2v  -- OPM�i�ڃJ�e�S�����VIEW2
-- Add 2008/05/29
    WHERE
    -- �ȉ��Œ����
    ------------------------------------------------------------------------
    -- ���Y�o�b�`�w�b�_����
          gbh.attribute4            =  gv_status_comp                   -- �Ɩ��X�e�[�^�X���u�����v
    ------------------------------------------------------------------------
    -- ���Y�����ڍ׏���
    AND   gbh.batch_id              =  gmd.batch_id
    AND   gmd.line_type             =  gv_line_type_kbn_seizouhin       -- ���C���^�C�v���u�����i�v
    ------------------------------------------------------------------------
    -- �H���}�X�^VIEW����
    AND   gbh.routing_id            =  grv.routing_id
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h���VIEW(�`�[�敪)����
    AND   grv.attribute13           =  xlv1v1.lookup_code
    AND   xlv1v1.lookup_type        =  gv_lookup_type_den_kbn
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h���VIEW(���ъǗ�����)����
    AND   grv.attribute14           =  xlv1v2.lookup_code
    AND   xlv1v2.lookup_type        =  gv_lookup_type_knri_bsho
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h���VIEW(�^�C�v)����
    AND   gmd.attribute1            =  xlv1v3.lookup_code(+)
    AND   xlv1v3.lookup_type(+)     =  gv_lookup_type_item_type
    ------------------------------------------------------------------------
    --  OPM�ۊǏꏊ���VIEW(�[�i�ꏊ)����
    AND   grv.attribute9            =  xil1v1.segment1
    ------------------------------------------------------------------------
    --  OPM�ۊǏꏊ���VIEW(�ړ��ꏊ)����
    AND   gmd.attribute12           =  xil1v2.segment1(+)
    ------------------------------------------------------------------------
    --  OPM�ۗ��݌Ƀg�����U�N�V��������
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
-- 2008/10/28 v1.7 D.Nihei ADD START
    AND itp.doc_type                = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
    -- ���L2������IS NULL�̑�ւƂ���
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp2
                      WHERE itp2.reverse_id = itp.trans_id)     -- �ۗ��g����ID�����o�[�XID�ɑ��݂��Ȃ�����
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp3
                      WHERE itp3.trans_id = itp.reverse_id)     -- ���o�[�XID���ۗ��g����ID�ɑ��݂��Ȃ�����
    AND   itp.completed_ind         =  gv_comp_flag             -- �����t���O���u�����v
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��view2����
    AND   gmd.item_id               =  xim2v.item_id
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                  BETWEEN xim2v.start_date_active
                                      AND xim2v.end_date_active
    ------------------------------------------------------------------------
-- Add 2008/05/29
    -- OPM�i�ڃJ�e�S�����view2����
    AND   gmd.item_id               =  xic2v.item_id
    AND   xic2v.category_set_name = FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV')
-- Add 2008/05/29
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    -- �ȉ��ϓ�����
    ------------------------------------------------------------------------
    -- �H���}�X�^VIEW�p�����[�^����
    AND   grv.attribute13           =  NVL(ir_param.iv_den_kbn , grv.attribute13)
    AND   grv.routing_no            =  NVL(ir_param.iv_line_no , grv.routing_no)
    ------------------------------------------------------------------------
    -- ���Y�o�b�`�w�b�_�p�����[�^����
    AND   gbh.plant_code            =  NVL(ir_param.iv_plant , gbh.plant_code)
    AND   gbh.batch_no              >= NVL(ir_param.id_tehai_no_from , gbh.batch_no)
    AND   gbh.batch_no              <= NVL(ir_param.id_tehai_no_to , gbh.batch_no)
-- �ύX START 2008/05/20 YTabata
/**
    AND   TRUNC(gbh.creation_date , 'MI') BETWEEN NVL(ir_param.id_input_date_from
                                                    , TRUNC(gbh.creation_date , 'MI'))
                                              AND NVL(ir_param.id_input_date_to
                                                    , TRUNC(gbh.creation_date , 'MI'))
**/
-- 2008/10/28 v1.7 D.Nihei MOD START
--    AND   gbh.creation_date  BETWEEN NVL(ir_param.id_input_date_from, gbh.creation_date )
--                                 AND NVL(ir_param.id_input_date_to, gbh.creation_date )
    AND   gbh.last_update_date  BETWEEN NVL(ir_param.id_input_date_from, gbh.last_update_date )
                                AND     NVL(ir_param.id_input_date_to,   gbh.last_update_date )
-- 2008/10/28 v1.7 D.Nihei MOD END
    ------------------------------------------------------------------------
    -- ���Y�����ڍ׃p�����[�^����
-- �ύX START 2008/05/20 YTabata
/**
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                    BETWEEN NVL(ir_param.id_make_date_from
                                              , FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                                                       ,gv_date_format3)
                                               )
                                        AND NVL(ir_param.id_make_date_to
                                              , FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10)
                                                                       ,gv_date_format3)
                                               )
**/
    AND   FND_DATE.STRING_TO_DATE(SUBSTRB(gmd.attribute11 , 1 , 10) , gv_date_format3)
                                    BETWEEN NVL(ir_param.id_make_date_from
                                              , FND_DATE.STRING_TO_DATE(gv_min_date_char
                                                                       ,gv_date_format3)
                                               )
                                        AND NVL(ir_param.id_make_date_to
                                              , FND_DATE.STRING_TO_DATE(gv_max_date_char
                                                                       ,gv_date_format3)
                                               )
-- �ύX END 2008/05/20 YTabata
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW2�p�����[�^����
    AND   xim2v.item_no             =  NVL(ir_param.iv_hinmoku_cd , xim2v.item_no)
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    ORDER BY gbh.batch_no
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_head_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_data
   * Description      : ����-������񒊏o
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_data(
      iv_batch_id      IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_tonyu_data    OUT NOCOPY type_tounyu_data_tbl             -- ����-�������f�[�^
     ,ov_errbuf        OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           gmd.material_detail_id                                    AS material_detail_id -- ���Y�����ڍ�.���Y�����ڍ�ID
          ,NVL(gmd.attribute8 , gv_tounyuguchi_kbn_default)          AS tounyuguchi_kbn    -- ���Y�����ڍ�.DFF8(�������敪)
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                                             AS tonyu_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                                     AS tonyu_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,ilm.lot_no                                                AS tonyu_lot_no       -- OPM���b�g�}�X�^.���b�gNo
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS tonyu_make_date    -- OPM���b�g�}�X�^.DFF1(�����N����)
          ,TO_NUMBER(ilm.attribute6)                                 AS tonyu_stock        -- OPM���b�g�}�X�^.DFF6(�݌ɓ���)
          ,xmd.invested_qty                                          AS tonyu_total        -- ���Y�����ڍ׃A�h�I��.��������
          ,xim1v.item_um                                             AS tonyu_unit         -- OPM�i�ڏ��VIEW.�P��
    --
    BULK COLLECT INTO ot_tonyu_data
    --
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL     -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL     -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u4:�����v
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   xmd.item_id               =  ilm.item_id
    AND   xmd.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     IN (gv_hinmoku_kbn_genryou
                                       ,gv_hinmoku_kbn_hanseihin
                                       ,gv_hinmoku_kbn_seihin)        -- ���ޗ��A�����i�A���i
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8            -- ���Y�����ڍ�.DFF8(�������敪)
            ,xic3v.item_class_code     -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)  -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
            ,TO_NUMBER(ilm.lot_no)     -- OPM���b�g�}�X�^.���b�gNO
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_tonyu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_tonyu_data
   * Description      : ����-�ߓ��i�������j��񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_tonyu_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_reinyu_tonyu_data    OUT NOCOPY type_tounyu_data_tbl             -- ����-�ߓ��i�������j���f�[�^
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_tonyu_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           gmd.material_detail_id                                    AS material_detail_id -- ���Y�����ڍ�.���Y�����ڍ�ID
          ,NVL(gmd.attribute8 , gv_tounyuguchi_kbn_default)          AS tounyuguchi_kbn    -- ���Y�����ڍ�.DFF8(�������敪)
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                                             AS modori_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                                     AS modori_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,ilm.lot_no                                                AS modori_lot_no       -- OPM���b�g�}�X�^.���b�gNO
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS modori_make_date    -- OPM���b�g�}�X�^.DFF1(�����N����)
          ,TO_NUMBER(ilm.attribute6)                                 AS modori_stock        -- OPM���b�g�}�X�^.DFF6(�݌ɓ���)
          ,xmd.return_qty                                            AS modori_total        -- ���Y�����ڍ׃A�h�I��.�ߓ�����
          ,xim1v.item_um                                             AS modori_unit         -- OPM�i�ڏ��VIEW.�P��
    --
    BULK COLLECT INTO ot_reinyu_tonyu_data
    --
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL     -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL     -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u4:�����v
    AND   NVL(xmd.return_qty,0)     <> 0         -- �ߓ����ʂ�0�łȂ�
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   xmd.item_id               =  ilm.item_id
    AND   xmd.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     IN (gv_hinmoku_kbn_genryou
                                       ,gv_hinmoku_kbn_hanseihin
                                       ,gv_hinmoku_kbn_seihin)  -- ���ޗ��A�����i�A���i
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8              -- ���Y�����ڍ�.DFF8(�������敪)
            ,xic3v.item_class_code       -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)    -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
            ,TO_NUMBER(ilm.lot_no)       -- OPM���b�g�}�X�^.���b�gNO
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_reinyu_tonyu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_fsanbutu_data
   * Description      : ����-���Y����񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_fsanbutu_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_fukusanbutu_data     OUT NOCOPY type_tounyu_data_tbl             -- ����-���Y�����f�[�^
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_fsanbutu_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                                           AS material_detail_id    -- �_�~�[�J����
          ,TO_CHAR(NULL)                                             AS tounyuguchi_kbn       -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                                             AS fsanbutu_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                                     AS fsanbutu_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,ilm.lot_no                                                AS fsanbutu_lot_no       -- OPM���b�g�}�X�^.���b�gno
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS fsanbutu_make_date    -- OPM���b�g�}�X�^.DFF1(�����N����)
          ,TO_NUMBER(ilm.attribute6)                                 AS fsanbutu_stock        -- OPM���b�g�}�X�^.DFF6(�݌ɓ���)
          ,gmd.actual_qty                                            AS fsanbutu_total        -- ���Y�����ڍ�.���ѐ���
          ,xim1v.item_um                                             AS fsanbutu_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_fukusanbutu_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories_v    xic1v   -- OPM�i�ڃJ�e�S���������VIEW
          ,ic_tran_pnd                itp     -- OPM�ۗ��݌Ƀg�����U�N�V����
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_fukusanbutu       -- ���C���^�C�v���u���Y���v
    AND   gmd.attribute24           IS NULL     -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW����
    AND   gmd.item_id               =  xic1v.item_id
    AND   xic1v.category_set_name   =  gv_item_cat_name_item_kbn
    ------------------------------------------------------------------------
    --  OPM�ۗ��݌Ƀg�����U�N�V��������
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
    --���L2������IS NULL�̑�ւƂ���
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp2
                      WHERE itp2.reverse_id = itp.trans_id)     -- �ۗ��g����id�����o�[�Xid�ɑ��݂��Ȃ�����
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp3
                      WHERE itp3.trans_id = itp.reverse_id)     -- ���o�[�Xid���ۗ��g����id�ɑ��݂��Ȃ�����
    AND   itp.completed_ind    =  gv_comp_flag                  -- �����t���O���u�����v
-- 2008/10/28 v1.7 D.Nihei ADD START
    AND itp.doc_type           = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic1v.segment1            -- OPM�i�ڃJ�e�S���������VIEW.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)  -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
            ,TO_NUMBER(ilm.lot_no)     -- OPM���b�g�}�X�^.���b�gno
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_fsanbutu_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_utikomi_data
   * Description      : ����-�ō���񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_utikomi_data(
      iv_batch_id         IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_utikomi_data     OUT NOCOPY type_tounyu_data_tbl             --  ����-�ō����f�[�^
     ,ov_errbuf           OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_utikomi_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                                        AS material_detail_id   -- �_�~�[�J����
          ,TO_CHAR(NULL)                                          AS tounyuguchi_kbn       -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                                          AS utikomi_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                                  AS utikomi_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,ilm.lot_no                                             AS utikomi_lot_no       -- OPM���b�g�}�X�^.���b�gno
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)               AS utikomi_make_date    -- OPM���b�g�}�X�^.DFF1(�����N����)
          ,TO_NUMBER(ilm.attribute6)                              AS utikomi_stock        -- OPM���b�g�}�X�^.DFF6(�݌ɓ���)
          ,xmd.invested_qty                                       AS utikomi_total        -- ���Y�����ڍ׃A�h�I��.��������
          ,xim1v.item_um                                          AS utikomi_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_utikomi_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
          ,ic_tran_pnd                itp     -- OPM�ۗ��݌Ƀg�����U�N�V����
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            =  gv_utikomi_kbn_utikomi         -- DFF5(�ō��敪)���x
    AND   gmd.attribute24           IS NULL     -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u4:�����v
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     IN (gv_hinmoku_kbn_genryou
                                       ,gv_hinmoku_kbn_hanseihin
                                       ,gv_hinmoku_kbn_seihin)  -- ���ޗ��A�����i�A���i
    ------------------------------------------------------------------------
    --  OPM�ۗ��݌Ƀg�����U�N�V��������
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
--
    AND   xmd.material_detail_id    =  itp.line_id
    AND   xmd.item_id               =  itp.item_id
    AND   xmd.lot_id                =  itp.lot_id
    --���L2������IS NULL�̑�ւƂ���
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp2
                      WHERE itp2.reverse_id = itp.trans_id)     -- �ۗ��g����id�����o�[�Xid�ɑ��݂��Ȃ�����
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp3
                      WHERE itp3.trans_id = itp.reverse_id)     -- ���o�[�Xid���ۗ��g����id�ɑ��݂��Ȃ�����
    AND   itp.completed_ind    =  gv_comp_flag                  -- �����t���O���u�����v
-- 2008/10/28 v1.7 D.Nihei ADD START
    AND   itp.doc_type              = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic3v.item_class_code      -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)   -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
            ,TO_NUMBER(ilm.lot_no)      -- OPM���b�g�}�X�^.���b�gno
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_utikomi_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_utikomi_data
   * Description      : ����-�ߓ��i�ō����j��񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_utikomi_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_reinyu_utikomi_data  OUT NOCOPY type_tounyu_data_tbl             -- ����-�ߓ��i�ō����j���f�[�^
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_utikomi_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                                           AS material_detail_id          -- �_�~�[�J����
          ,TO_CHAR(NULL)                                             AS tounyuguchi_kbn             -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                                             AS modori_utikomi_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                                     AS modori_utikomi_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,ilm.lot_no                                                AS modori_utikomi_lot_no       -- OPM���b�g�}�X�^.���b�gNo
          ,FND_DATE.STRING_TO_DATE(SUBSTRB(ilm.attribute1 , 1 , 10)
                                  ,gv_date_format3)                  AS modori_utikomi_make_date    -- OPM���b�g�}�X�^.DFF1(�����N����)
          ,TO_NUMBER(ilm.attribute6)                                 AS modori_utikomi_stock        -- OPM���b�g�}�X�^.DFF6(�݌ɓ���)
          ,xmd.return_qty                                            AS modori_utikomi_total        -- ���Y�����ڍ׃A�h�I��.�ߓ�����
          ,xim1v.item_um                                             AS modori_utikomi_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_reinyu_utikomi_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,ic_lots_mst                ilm     -- OPM���b�g�}�X�^
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
          ,ic_tran_pnd                itp     -- OPM�ۗ��݌Ƀg�����U�N�V����
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou    -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            = gv_utikomi_kbn_utikomi       -- DFF5(�ō��敪)���x
    AND   gmd.attribute24           IS NULL                        -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u4:�����v
    AND   NVL(xmd.return_qty,0)     <> 0         -- �ߓ����ʂ�0�łȂ�
    ------------------------------------------------------------------------
    -- OPM���b�g�}�X�^����
    AND   itp.item_id               =  ilm.item_id
    AND   itp.lot_id                =  ilm.lot_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    --  OPM�ۗ��݌Ƀg�����U�N�V��������
    AND   gmd.batch_id              =  itp.doc_id
    AND   gmd.material_detail_id    =  itp.line_id
    AND   gmd.line_type             =  itp.line_type
--
    AND   xmd.material_detail_id    =  itp.line_id
    AND   xmd.item_id               =  itp.item_id
    AND   xmd.lot_id                =  itp.lot_id
-- 2008/10/28 v1.7 D.Nihei ADD START
    AND itp.doc_type                = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
    --���L2������IS NULL�̑�ւƂ���
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp2
                      WHERE itp2.reverse_id = itp.trans_id)     -- �ۗ��g����ID�����o�[�XID�ɑ��݂��Ȃ�����
    AND   NOT EXISTS (SELECT 1
                      FROM ic_tran_pnd itp3
                      WHERE itp3.trans_id = itp.reverse_id)     -- ���o�[�XID���ۗ��g����ID�ɑ��݂��Ȃ�����
    AND   itp.completed_ind    =  gv_comp_flag                  -- �����t���O���u�����v
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     IN (gv_hinmoku_kbn_genryou
                                       ,gv_hinmoku_kbn_hanseihin
                                       ,gv_hinmoku_kbn_seihin)  -- ���ޗ��A�����i�A���i
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY gmd.attribute8             -- ���Y�����ڍ�.DFF8(�������敪)
            ,xic3v.item_class_code      -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)   -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
            ,TO_NUMBER(ilm.lot_no)      -- OPM���b�g�}�X�^.���b�gNo
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_reinyu_utikomi_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_sizai_data
   * Description      : ����-�������ޏ�񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_sizai_data(
      iv_batch_id             IN         gme_batch_header.batch_id%TYPE  -- �o�b�`ID
     ,ot_tonyu_sizai_data     OUT NOCOPY type_tounyu_data_tbl             -- ����-�������ޏ��f�[�^
     ,ov_errbuf               OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_sizai_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                         AS material_detail_id       -- �_�~�[�J����
          ,TO_CHAR(NULL)                           AS tounyuguchi_kbn          -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                           AS tonyu_sizai_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                   AS tonyu_sizai_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,TO_CHAR(NULL)                           AS tonyu_sizai_lot_no       -- �_�~�[�J����
          ,TO_DATE(NULL)                           AS tonyu_sizai_make_date    -- �_�~�[�J����
          ,TO_NUMBER(NULL)                         AS tonyu_sizai_stock        -- �_�~�[�J����
          ,xmd.invested_qty                        AS tonyu_sizai_total        -- ���Y�����ڍ׃A�h�I��.��������
          ,xim1v.item_um                           AS tonyu_sizai_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_tonyu_sizai_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou   -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL                       -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL                       -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u�����v
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     =  gv_hinmoku_kbn_sizai                      -- ����
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic3v.item_class_code     -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)  -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_tonyu_sizai_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_reinyu_sizai_data
   * Description      : ����-�ߓ����ޏ�񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_reinyu_sizai_data(
      iv_batch_id           IN         gme_batch_header.batch_id%TYPE   -- �o�b�`ID
     ,ot_reinyu_sizai_data  OUT NOCOPY type_tounyu_data_tbl              -- ����-�ߓ����ޏ��f�[�^
     ,ov_errbuf             OUT NOCOPY VARCHAR2                         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT NOCOPY VARCHAR2                         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT NOCOPY VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_reinyu_sizai_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                         AS material_detail_id        -- �_�~�[�J����
          ,TO_CHAR(NULL)                           AS tounyuguchi_kbn           -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                           AS modori_sizai_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                   AS modori_sizai_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,TO_CHAR(NULL)                           AS modori_sizai_lot_no       -- �_�~�[�J����
          ,TO_DATE(NULL)                           AS modori_sizaii_make_date   -- �_�~�[�J����
          ,TO_NUMBER(NULL)                         AS modori_sizai_stock        -- �_�~�[�J����
          ,xmd.return_qty                          AS modori_sizai_total        -- ���Y�����ڍ׃A�h�I��.�ߓ�����
          ,xim1v.item_um                           AS modori_sizai_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_reinyu_sizai_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL                           -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL                           -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u�����v
    AND   NVL(xmd.return_qty,0)     <> 0         -- �ߓ����ʂ�0�łȂ�
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     =  gv_hinmoku_kbn_sizai                      -- ����
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic3v.item_class_code      -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)   -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_reinyu_sizai_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_seizou_furyo_data
   * Description      : ����-�����s�Ǐ�񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_seizou_furyo_data(
      iv_batch_id              IN         gme_batch_header.batch_id%TYPE   -- �o�b�`ID
     ,ot_seizou_furyo_data     OUT NOCOPY type_tounyu_data_tbl              -- ����-�����s�Ǐ��f�[�^
     ,ov_errbuf                OUT NOCOPY VARCHAR2                         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2                         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_seizou_furyo_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                         AS material_detail_id       -- �_�~�[�J����
          ,TO_CHAR(NULL)                           AS tounyuguchi_kbn          -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                           AS make_furyou_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                   AS make_furyou_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,TO_CHAR(NULL)                           AS make_furyou_lot_no       -- �_�~�[�J����
          ,TO_DATE(NULL)                           AS make_furyou_make_date    -- �_�~�[�J����
          ,TO_NUMBER(NULL)                         AS make_furyou_stock        -- �_�~�[�J����
          ,xmd.mtl_prod_qty                        AS make_furyou_total        -- ���Y�����ڍ׃A�h�I��.���ސ����s�ǐ�
          ,xim1v.item_um                           AS make_furyou_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_seizou_furyo_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL                           -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL     -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u�����v
    AND   NVL(xmd.mtl_prod_qty,0)   <> 0         -- ���ސ����s�ǐ���0�łȂ�
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     =  gv_hinmoku_kbn_sizai                      -- ����
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic3v.item_class_code      -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)   -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_seizou_furyo_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_gyousha_furyo_data
   * Description      : ����-�Ǝҕs�Ǐ�񒊏o����
   ***********************************************************************************/
  PROCEDURE prc_get_gyousha_furyo_data(
      iv_batch_id              IN         gme_batch_header.batch_id%TYPE   -- �o�b�`ID
     ,ot_gyousha_furyo_data    OUT NOCOPY type_tounyu_data_tbl              -- ����-�Ǝҕs�Ǐ��f�[�^
     ,ov_errbuf                OUT NOCOPY VARCHAR2                         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2                         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_gyousha_furyo_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT
           --�ȉ������p����
           TO_NUMBER(NULL)                         AS material_detail_id         -- �_�~�[�J����
          ,TO_CHAR(NULL)                           AS tounyuguchi_kbn            -- �_�~�[�J����
           --�ȉ��f�[�^�p����
          ,xim1v.item_no                           AS gyosya_furyou_hinmk_cd     -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,xim1v.item_short_name                   AS gyosya_furyou_hinmk_nm     -- OPM�i�ڏ��VIEW.�i���E����
          ,TO_CHAR(NULL)                           AS gyosya_furyou_lot_no       -- �_�~�[�J����
          ,TO_DATE(NULL)                           AS gyosya_furyou_make_date    -- �_�~�[�J����
          ,TO_NUMBER(NULL)                         AS gyosya_furyou_stock        -- �_�~�[�J����
          ,xmd.mtl_mfg_qty                         AS gyosya_furyou_total        -- ���Y�����ڍ׃A�h�I��.���ދƎҕs�ǐ�
          ,xim1v.item_um                           AS gyosya_furyou_unit         -- OPM�i�ڏ��VIEW.�P��
--
    BULK COLLECT INTO ot_gyousha_furyo_data
--
    FROM   gme_material_details       gmd     -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd     -- ���Y�����ڍ׃A�h�I��
          ,xxcmn_item_mst_v           xim1v   -- OPM�i�ڏ��VIEW
          ,xxcmn_item_categories3_v   xic3v   -- OPM�i�ڃJ�e�S���������VIEW3
    WHERE
    --�ȉ��Œ����
    ------------------------------------------------------------------------
    --���Y�����ڍ׏���
          gmd.line_type             =  gv_line_type_kbn_genryou       -- ���C���^�C�v���u�����v
    AND   gmd.attribute5            IS NULL                           -- DFF5(�ō��敪)��������
    AND   gmd.attribute24           IS NULL                           -- DFF24(�����폜�t���O)��������
    ------------------------------------------------------------------------
    --���Y�����ڍ׃A�h�I������
    AND   gmd.material_detail_id    =  xmd.material_detail_id
    AND   xmd.plan_type             =  gv_yotei_kbn_tonyu       -- �\��敪���u�����v
    AND   NVL(xmd.mtl_mfg_qty,0)    <> 0         -- ���ދƎҕs�ǐ���0�łȂ�
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND   gmd.item_id               =  xim1v.item_id
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW3����
    AND   gmd.item_id               =  xic3v.item_id
    AND   xic3v.item_class_code     =  gv_hinmoku_kbn_sizai                      -- ����
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    --�ȉ��ϓ�����
    ------------------------------------------------------------------------
    --���Y�����ڍ׃p�����[�^����
    AND   gmd.batch_id              =  iv_batch_id
    ------------------------------------------------------------------------
    ORDER BY xic3v.item_class_code      -- OPM�i�ڃJ�e�S���������VIEW3.�i�ڃJ�e�S���R�[�h
            ,TO_NUMBER(xim1v.item_no)   -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
    ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_gyousha_furyo_data;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_data
   * Description      : �p�����[�^�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE prc_check_param_data(
      iv_den_kbn           IN            VARCHAR2         -- 01 : �`�[�敪
     ,iv_plant             IN            VARCHAR2         -- 02 : �v�����g
     ,iv_line_no           IN            VARCHAR2         -- 03 : ���C��No
     ,iv_make_date_from    IN            VARCHAR2         -- 04 : ���Y��(FROM)
     ,iv_make_date_to      IN            VARCHAR2         -- 05 : ���Y��(TO)
     ,iv_tehai_no_from     IN            VARCHAR2         -- 06 : ��zNo(FROM)
     ,iv_tehai_no_to       IN            VARCHAR2         -- 07 : ��zNo(TO)
     ,iv_hinmoku_cd        IN            VARCHAR2         -- 08 : �i�ڃR�[�h
     ,iv_input_date_from   IN            VARCHAR2         -- 09 : ���͓���(FROM)
     ,iv_input_date_to     IN            VARCHAR2         -- 10 : ���͓���(TO)
     ,id_now_date          IN            DATE             -- ���ݓ��t
     ,or_param             OUT NOCOPY    type_param_rec   -- ���̓p�����[�^
     ,ov_errbuf            OUT NOCOPY    VARCHAR2         -- �G���[�E���b�Z�[�W             --# �Œ� #
     ,ov_retcode           OUT NOCOPY    VARCHAR2         -- ���^�[���E�R�[�h               --# �Œ� #
     ,ov_errmsg            OUT NOCOPY    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_check_param_data'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N�Ȃ��̃p�����[�^�i�[
    or_param.iv_den_kbn          := iv_den_kbn;                                  -- 01 : �`�[�敪
    or_param.iv_plant            := iv_plant;                                    -- 02 : �v�����g
    or_param.iv_line_no          := iv_line_no;                                  -- 03 : ���C��No
    or_param.id_tehai_no_from    := iv_tehai_no_from;                            -- 06 : ��zNo(FROM)
    or_param.id_tehai_no_to      := iv_tehai_no_to;                              -- 07 : ��zNo(TO)
    or_param.iv_hinmoku_cd       := iv_hinmoku_cd;                               -- 08 : �i�ڃR�[�h
--
    -- ====================================================
    -- ���Y��(FROM)�t�H�[�}�b�g�`�F�b�N
    -- ====================================================
    IF (iv_make_date_from IS NOT NULL) THEN
      -- ���͂�����ꍇ�Ɏ��{
      validate_date_format(
            iv_validate_date   => iv_make_date_from                  -- �`�F�b�N�Ώۓ��t
           ,iv_err_item_val    => gv_err_make_date_from              -- �G���[���ږ���
           ,iv_date_format     => gv_date_format3                    -- �ϊ��t�H�[�}�b�g
           ,od_change_date     => or_param.id_make_date_from         -- �ϊ�����t
           ,ov_errbuf          => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode         => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg          => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ====================================================
    -- ���Y��(TO)�t�H�[�}�b�g�`�F�b�N
    -- ====================================================
    IF (iv_make_date_to IS NOT NULL) THEN
      -- ���͂�����ꍇ�Ɏ��{
      validate_date_format(
            iv_validate_date   => iv_make_date_to                    -- �`�F�b�N�Ώۓ��t
           ,iv_err_item_val    => gv_err_make_date_to                -- �G���[���ږ���
           ,iv_date_format     => gv_date_format3                    -- �ϊ��t�H�[�}�b�g
           ,od_change_date     => or_param.id_make_date_to           -- �ϊ�����t
           ,ov_errbuf          => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode         => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg          => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ====================================================
    -- ���͓���(FROM)�t�H�[�}�b�g�`�F�b�N
    -- ====================================================
    validate_date_format(
          iv_validate_date   => iv_input_date_from                 -- �`�F�b�N�Ώۓ��t
         ,iv_err_item_val    => gv_err_input_date_from             -- �G���[���ږ���
-- �ύX START 2008/05/02 Oikawa
         ,iv_date_format     => gv_date_format1                    -- �ϊ��t�H�[�}�b�g
--         ,iv_date_format     => gv_date_format2                    -- �ϊ��t�H�[�}�b�g
-- �ύX END
         ,od_change_date     => or_param.id_input_date_from        -- �ϊ�����t
         ,ov_errbuf          => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode         => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg          => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ���͓���(TO)�t�H�[�}�b�g�`�F�b�N
    -- ====================================================
    validate_date_format(
          iv_validate_date   => iv_input_date_to                   -- �`�F�b�N�Ώۓ��t
         ,iv_err_item_val    => gv_err_input_date_to               -- �G���[���ږ���
-- �ύX START 2008/05/02 Oikawa
         ,iv_date_format     => gv_date_format1                    -- �ϊ��t�H�[�}�b�g
--         ,iv_date_format     => gv_date_format2                    -- �ϊ��t�H�[�}�b�g
-- �ύX END
         ,od_change_date     => or_param.id_input_date_to          -- �ϊ�����t
         ,ov_errbuf          => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode         => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg          => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �������`�F�b�N�@���͓����iFROM�j
    -- ====================================================
    IF (TRUNC(or_param.id_input_date_from, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,TO_CHAR(or_param.id_input_date_from, gv_date_format2)) ;
      RAISE global_process_expt ;
    END IF;
--    
    -- ====================================================
    -- �������`�F�b�N�@���͓����iTO�j
    -- ====================================================
    IF (TRUNC(or_param.id_input_date_to, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,TO_CHAR(or_param.id_input_date_to, gv_date_format2)) ;
      RAISE global_process_expt ;
    END IF;
--
    -- ====================================================
    -- �Ó����`�F�b�N�@���Y���iFROM/TO�j
    -- ====================================================
    IF (or_param.id_make_date_from > or_param.id_make_date_to) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_make_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_make_date_to) ;
      RAISE global_process_expt ;
    END IF;
--
    -- ====================================================
    -- �Ó����`�F�b�N�@���͓����iFROM/TO�j
    -- ====================================================
    IF (or_param.id_input_date_from > or_param.id_input_date_to) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_input_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_input_date_to) ;
      RAISE global_process_expt ;
    END IF;
--
  EXCEPTION
--
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END prc_check_param_data ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_den_kbn           IN      VARCHAR2         -- 01 : �`�[�敪
     ,iv_plant             IN      VARCHAR2         -- 02 : �v�����g
     ,iv_line_no           IN      VARCHAR2         -- 03 : ���C��No
     ,iv_make_date_from    IN      VARCHAR2         -- 04 : ���Y��(FROM)
     ,iv_make_date_to      IN      VARCHAR2         -- 05 : ���Y��(TO)
     ,iv_tehai_no_from     IN      VARCHAR2         -- 06 : ��zNo(FROM)
     ,iv_tehai_no_to       IN      VARCHAR2         -- 07 : ��zNo(TO)
     ,iv_hinmoku_cd        IN      VARCHAR2         -- 08 : �i�ڃR�[�h
     ,iv_input_date_from   IN      VARCHAR2         -- 09 : ���͓���(FROM)
     ,iv_input_date_to     IN      VARCHAR2         -- 10 : ���͓���(TO)
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h            --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    lr_param_rec            type_param_rec ;         -- �p�����[�^��n���p
    lt_head_data            type_head_data_tbl ;     -- �擾���R�[�h�\�i�w�b�_���j
    lt_tonyu_data           type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�������j
    lt_reinyu_tonyu_data    type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�ߓ��i�������j���j
    lt_fukusanbutu_data     type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-���Y�����j
    lt_utikomi_data         type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�ō����j
    lt_reinyu_utikomi_data  type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�ߓ��i�ō����j���j
    lt_tonyu_sizai_data     type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�������ޏ��j
    lt_reinyu_sizai_data    type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�ߓ����ޏ��j
    lt_seizou_furyo_data    type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�����s�Ǐ��j
    lt_gyousha_furyo_data   type_tounyu_data_tbl ;    -- �擾���R�[�h�\�i����-�Ǝҕs�Ǐ��j
--
    -- �V�X�e�����t
    ld_now_date             DATE DEFAULT SYSDATE;
    -- ���[�v�J�E���^�ϐ�
    ln_loop_cnt             PLS_INTEGER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_data(
      iv_den_kbn           =>     iv_den_kbn           -- 01 : �`�[�敪
     ,iv_plant             =>     iv_plant             -- 02 : �v�����g
     ,iv_line_no           =>     iv_line_no           -- 03 : ���C��No
     ,iv_make_date_from    =>     iv_make_date_from  -- 04 : ���Y��(FROM)
     ,iv_make_date_to      =>     iv_make_date_to    -- 05 : ���Y��(TO)
     ,iv_tehai_no_from     =>     iv_tehai_no_from     -- 06 : ��zNo(FROM)
     ,iv_tehai_no_to       =>     iv_tehai_no_to       -- 07 : ��zNo(TO)
     ,iv_hinmoku_cd        =>     iv_hinmoku_cd        -- 08 : �i�ڃR�[�h
     ,iv_input_date_from   =>     iv_input_date_from   -- 09 : ���͓���(FROM)
     ,iv_input_date_to     =>     iv_input_date_to     -- 10 : ���͓���(TO)
     ,id_now_date          =>     ld_now_date          -- ���ݓ��t
     ,or_param             =>     lr_param_rec         -- ���̓p�����[�^
     ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W             --# �Œ� #
     ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h               --# �Œ� #
     ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�b�_�[��񒊏o����
    -- =====================================================
    prc_get_head_data(
        ir_param          =>   lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ot_head_data      =>   lt_head_data       -- �擾���R�[�h�Q
       ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    --�w�b�_��񃋁[�v
    <<head_data_loop>>
    FOR ln_loop_cnt IN 1..lt_head_data.COUNT LOOP
--
      -- =====================================================
      -- ����-������񒊏o����
      -- =====================================================
      prc_get_tonyu_data(
         iv_batch_id     => lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
        ,ot_tonyu_data   => lt_tonyu_data                          -- ����-�������f�[�^
        ,ov_errbuf       => lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ����-�ߓ��i�������j��񒊏o����
      -- =====================================================
      prc_get_reinyu_tonyu_data(
           iv_batch_id             =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
          ,ot_reinyu_tonyu_data    =>   lt_reinyu_tonyu_data                   -- ����-�ߓ��i�������j���f�[�^
          ,ov_errbuf               =>   lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode              =>   lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg               =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ����-���Y����񒊏o����
      -- =====================================================
      prc_get_fsanbutu_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_fukusanbutu_data   =>   lt_fukusanbutu_data                    -- �擾���R�[�h�Q
         ,ov_errbuf             =>   lv_errbuf                              -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode            =>   lv_retcode                             -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg             =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- ����-�ō���񒊏o����
      -- =====================================================
      prc_get_utikomi_data(
          iv_batch_id       =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_utikomi_data   =>   lt_utikomi_data                        -- ����-�ō����f�[�^
         ,ov_errbuf         =>   lv_errbuf                              -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode        =>   lv_retcode                             -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg         =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- ����-�ߓ��i�ō����j��񒊏o����
      -- =====================================================
      prc_get_reinyu_utikomi_data(
          iv_batch_id              =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_reinyu_utikomi_data   =>   lt_reinyu_utikomi_data                 -- ����-�ߓ��i�ō����j���f�[�^
         ,ov_errbuf                =>   lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode               =>   lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- ����-�������ޏ�񒊏o����
      -- =====================================================
      prc_get_tonyu_sizai_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_tonyu_sizai_data   =>   lt_tonyu_sizai_data                    -- ����-�������ޏ��f�[�^
         ,ov_errbuf             =>   lv_errbuf                              -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode            =>   lv_retcode                             -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg             =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- ����-�ߓ����ޏ�񒊏o����
      -- =====================================================
      prc_get_reinyu_sizai_data(
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_reinyu_sizai_data  =>   lt_reinyu_sizai_data                   -- ����-�ߓ����ޏ��f�[�^
         ,ov_errbuf             =>   lv_errbuf                              -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode            =>   lv_retcode                             -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg             =>   lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- ����-�����s�Ǐ�񒊏o����
      -- =====================================================
      prc_get_seizou_furyo_data
        (
          iv_batch_id           =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_seizou_furyo_data  =>   lt_seizou_furyo_data         -- ����-�����s�Ǐ��f�[�^
         ,ov_errbuf             =>   lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode            =>   lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg             =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ����-�Ǝҕs�Ǐ�񒊏o����
      -- =====================================================
      prc_get_gyousha_furyo_data(
          iv_batch_id             =>   lt_head_data(ln_loop_cnt).l_batch_id   -- �o�b�`ID
         ,ot_gyousha_furyo_data   =>   lt_gyousha_furyo_data        -- ����-�Ǝҕs�Ǐ��f�[�^
         ,ov_errbuf               =>   lv_errbuf                    -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode              =>   lv_retcode                   -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg               =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
--
      -- =====================================================
      -- XML�f�[�^�쐬����
      -- =====================================================
      prc_create_xml_data(
          ir_param_rec           =>   lr_param_rec               -- ���̓p�����[�^���R�[�h
         ,ir_head_data           =>   lt_head_data(ln_loop_cnt)  -- �w�b�_�[���
         ,it_tonyu_data          =>   lt_tonyu_data              -- �������
         ,it_reinyu_tonyu_data   =>   lt_reinyu_tonyu_data       -- ����-�ߓ��i�������j���
         ,it_fukusanbutu_data    =>   lt_fukusanbutu_data        -- ����-���Y�����
         ,it_utikomi_data        =>   lt_utikomi_data            -- ����-�ō����
         ,it_reinyu_utikomi_data =>   lt_reinyu_utikomi_data     -- ����-�ߓ��i�ō����j���
         ,it_tonyu_sizai_data    =>   lt_tonyu_sizai_data        -- ����-�������ޏ��
         ,it_reinyu_sizai_data   =>   lt_reinyu_sizai_data       -- ����-�ߓ����ޏ��
         ,it_seizou_furyo_data   =>   lt_seizou_furyo_data       -- ����-�����s�Ǐ��
         ,it_gyousha_furyo_data  =>   lt_gyousha_furyo_data      -- ����-�Ǝҕs�Ǐ��
         ,id_now_date            =>   ld_now_date                -- ���ݓ��t
         ,ov_errbuf              =>   lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode             =>   lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg              =>   lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ���׏�񏉊���
      -- =====================================================
      lt_tonyu_data.DELETE;            -- �擾���R�[�h�\�i����-�������j
      lt_reinyu_tonyu_data.DELETE;     -- �擾���R�[�h�\�i����-�ߓ��i�������j���j
      lt_fukusanbutu_data.DELETE;      -- �擾���R�[�h�\�i����-���Y�����j
      lt_utikomi_data.DELETE;          -- �擾���R�[�h�\�i����-�ō����j
      lt_reinyu_utikomi_data.DELETE;   -- �擾���R�[�h�\�i����-�ߓ��i�ō����j���j
      lt_tonyu_sizai_data.DELETE;      -- �擾���R�[�h�\�i����-�������ޏ��j
      lt_reinyu_sizai_data.DELETE;     -- �擾���R�[�h�\�i����-�ߓ����ޏ��j
      lt_seizou_furyo_data.DELETE;     -- �擾���R�[�h�\�i����-�����s�Ǐ��j
      lt_gyousha_furyo_data.DELETE;    -- �擾���R�[�h�\�i����-�Ǝҕs�Ǐ��j
--
    END LOOP head_data_loop ;
--
    IF (lt_head_data.COUNT = 0) THEN
--
      -- =====================================================
      -- �擾�f�[�^�O����XML�f�[�^�쐬����
      -- =====================================================
      prc_create_zeroken_xml_data(
          ir_param          =>   lr_param_rec       -- ���̓p�����[�^���R�[�h
         ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- =====================================================
    -- XML�f�[�^�o�͏���
    -- =====================================================
    prc_out_xml_data(
        ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN   -- ���^�[���R�[�h���u�G���[�v
      RAISE global_process_expt ;
--
    ELSIF (    (lv_retcode = gv_status_normal)
           AND (lt_head_data.COUNT = 0)) THEN  -- ���^�[���R�[�h���u����v��������0��
      lv_retcode := gv_status_warn;
--
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END submain ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : �`�[�敪
     ,iv_plant              IN     VARCHAR2         -- 02 : �v�����g
     ,iv_line_no            IN     VARCHAR2         -- 03 : ���C��No
     ,iv_make_date_from     IN     VARCHAR2         -- 04 : ���Y��(FROM)
     ,iv_make_date_to       IN     VARCHAR2         -- 05 : ���Y��(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 06 : ��zNo(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 07 : ��zNo(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 08 : �i�ڃR�[�h
     ,iv_input_date_from    IN     VARCHAR2         -- 09 : ���͓���(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 10 : ���͓���(TO)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_den_kbn            => iv_den_kbn           -- 01 : �`�[�敪
       ,iv_plant              => iv_plant             -- 02 : �v�����g
       ,iv_line_no            => iv_line_no           -- 03 : ���C��No
       ,iv_make_date_from     => iv_make_date_from    -- 04 : ���Y��(FROM)
       ,iv_make_date_to       => iv_make_date_to      -- 05 : ���Y��(TO)
       ,iv_tehai_no_from      => iv_tehai_no_from     -- 06 : ��zNo(FROM)
       ,iv_tehai_no_to        => iv_tehai_no_to       -- 07 : ��zNo(TO)
       ,iv_hinmoku_cd         => iv_hinmoku_cd        -- 08 : �i�ڃR�[�h
       ,iv_input_date_from    => iv_input_date_from   -- 09 : ���͓���(FROM)
       ,iv_input_date_to      => iv_input_date_to     -- 10 : ���͓���(TO)
       ,ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
--
--
END xxwip230002c ;
/
