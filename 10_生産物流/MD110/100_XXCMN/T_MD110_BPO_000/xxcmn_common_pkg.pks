CREATE OR REPLACE PACKAGE xxcmn_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common_pkg(SPEC)
 * Description            : ���ʊ֐�(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.6
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_msg                F   VAR   Message�擾
 *  get_user_name          F   VAR   �S���Җ��擾
 *  get_user_dept          F   VAR   �S���������擾
 *  get_tbl_lock           F   BOL   �e�[�u�����b�N�֐�
 *  del_all_data           F   BOL   �e�[�u���f�[�^�ꊇ�폜�֐�
 *  get_opminv_close_period
 *                         F   VAR   OPM�݌ɉ�v����CLOSE�N���擾�֐�
 *  get_category_desc      F   VAR   �J�e�S���擾�֐�
 *  get_sagara_factory_info
 *                         P         �ɓ������ǍH����擾�v���V�[�W��
 *  get_calender_cd        F   VAR   �J�����_�R�[�h�擾�֐�
 *  check_oprtn_day        F   NUM   �ғ����`�F�b�N�֐�
 *  get_seq_no             P         �̔Ԋ֐�
 *  get_dept_info          P         �������擾�v���V�[�W��
 *  get_term_of_payment    F   VAR   �x�����������擾�֐�
 *  check_param_date_yyyymm
 *                         F   NUM   �p�����[�^�`�F�b�N�F���t�`���iYYYYMM�j
 *  check_param_date_yyyymmdd
 *                         F   NUM   �p�����[�^�`�F�b�N�F���t�`���iYYYYMMDD HH24:MI:SS�j
 *  put_api_log            P   �Ȃ�  �W��API���O�o��API
 *  get_outbound_info      P   �Ȃ�  �A�E�g�o�E���h�������擾�֐�
 *  upd_outbound_info      P   �Ȃ�  �t�@�C���o�͏��X�V�֐�
 *  wf_start               P   �Ȃ�  ���[�N�t���[�N���֐�
 *  get_can_enc_total_qty  F   NUM   �������\���Z�oAPI
 *  get_can_enc_in_time_qty
 *                         F   NUM   �L�����x�[�X�����\���Z�oAPI
 *  get_stock_qty          F   NUM   �莝�݌ɐ��ʎZ�oAPI
 *  get_can_enc_qty        F   NUM   �����\���Z�oAPI
 *  rcv_ship_conv_qty      F   NUM   ���o�Ɋ��Z�֐�(���Y�o�b�`�p)
 *  get_user_dept_code     F   VAR   �S������CD�擾
 *  create_lot_mst_history P         ���b�g�}�X�^�����쐬�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/07   1.0   marushita        �V�K�쐬
 *  2008/05/07   1.1   marushita        WF�N���֐���WF�N�����p�����[�^��WF�I�[�i�[��ǉ�
 *  2008/09/18   1.2   Oracle �R�� ��_ T_S_453�Ή�(WF�t�@�C���R�s�[)
 *  2008/09/30   1.3   Yuko Kawano      OPM�݌ɉ�v����CLOSE�N���擾�֐� T_S_500�Ή�
 *  2008/10/29   1.4   T.Yoshimoto      �����w�E�Ή�(No.251)
 *  2008/12/29   1.5   A.Shiina         [�̔Ԋ֐�]���I�ɏC��
 *  2019/09/19   1.6   Y.Ohishi         ���b�g�}�X�^�����쐬�֐���ǉ�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
  TYPE outbound_rec IS RECORD(
--    wf_ope_div              xxcmn_outbound.wf_ope_div%TYPE,
    wf_class                xxcmn_outbound.wf_class%TYPE,
    wf_notification         xxcmn_outbound.wf_notification%TYPE,
    directory               VARCHAR2(150),
    file_name               VARCHAR2(150),
    file_display_name       VARCHAR2(150),
    file_last_update_date   xxcmn_outbound.file_last_update_date%TYPE,
    wf_name                 VARCHAR2(150),
    wf_owner                VARCHAR2(150),
    user_cd01               VARCHAR2(150),
    user_cd02               VARCHAR2(150),
    user_cd03               VARCHAR2(150),
    user_cd04               VARCHAR2(150),
    user_cd05               VARCHAR2(150),
    user_cd06               VARCHAR2(150),
    user_cd07               VARCHAR2(150),
    user_cd08               VARCHAR2(150),
    user_cd09               VARCHAR2(150),
    user_cd10               VARCHAR2(150)
  );
--
-- Ver_1.6 E_�{�ғ�_15887 ADD Start
  TYPE lot_rec IS RECORD(
    item_id                       ic_lots_mst.item_id%TYPE,
    lot_id                        ic_lots_mst.lot_id%TYPE,
    lot_no                        ic_lots_mst.lot_no%TYPE,
    sublot_no                     ic_lots_mst.sublot_no%TYPE,
    lot_desc                      ic_lots_mst.lot_desc%TYPE,
    qc_grade                      ic_lots_mst.qc_grade%TYPE,
    expaction_code                ic_lots_mst.expaction_code%TYPE,
    expaction_date                ic_lots_mst.expaction_date%TYPE,
    lot_created                   ic_lots_mst.lot_created%TYPE,
    expire_date                   ic_lots_mst.expire_date%TYPE,
    retest_date                   ic_lots_mst.retest_date%TYPE,
    strength                      ic_lots_mst.strength%TYPE,
    inactive_ind                  ic_lots_mst.inactive_ind%TYPE,
    origination_type              ic_lots_mst.origination_type%TYPE,
    shipvend_id                   ic_lots_mst.shipvend_id%TYPE,
    vendor_lot_no                 ic_lots_mst.vendor_lot_no%TYPE,
    creation_date                 ic_lots_mst.creation_date%TYPE,
    last_update_date              ic_lots_mst.last_update_date%TYPE,
    created_by                    ic_lots_mst.created_by%TYPE,
    last_updated_by               ic_lots_mst.last_updated_by%TYPE,
    trans_cnt                     ic_lots_mst.trans_cnt%TYPE,
    delete_mark                   ic_lots_mst.delete_mark%TYPE,
    text_code                     ic_lots_mst.text_code%TYPE,
    last_update_login             ic_lots_mst.last_update_login%TYPE,
    program_application_id        ic_lots_mst.program_application_id%TYPE,
    program_id                    ic_lots_mst.program_id%TYPE,
    program_update_date           ic_lots_mst.program_update_date%TYPE,
    request_id                    ic_lots_mst.request_id%TYPE,
    attribute1                    ic_lots_mst.attribute1%TYPE,
    attribute2                    ic_lots_mst.attribute2%TYPE,
    attribute3                    ic_lots_mst.attribute3%TYPE,
    attribute4                    ic_lots_mst.attribute4%TYPE,
    attribute5                    ic_lots_mst.attribute5%TYPE,
    attribute6                    ic_lots_mst.attribute6%TYPE,
    attribute7                    ic_lots_mst.attribute7%TYPE,
    attribute8                    ic_lots_mst.attribute8%TYPE,
    attribute9                    ic_lots_mst.attribute9%TYPE,
    attribute10                   ic_lots_mst.attribute10%TYPE,
    attribute11                   ic_lots_mst.attribute11%TYPE,
    attribute12                   ic_lots_mst.attribute12%TYPE,
    attribute13                   ic_lots_mst.attribute13%TYPE,
    attribute14                   ic_lots_mst.attribute14%TYPE,
    attribute15                   ic_lots_mst.attribute15%TYPE,
    attribute16                   ic_lots_mst.attribute16%TYPE,
    attribute17                   ic_lots_mst.attribute17%TYPE,
    attribute18                   ic_lots_mst.attribute18%TYPE,
    attribute19                   ic_lots_mst.attribute19%TYPE,
    attribute20                   ic_lots_mst.attribute20%TYPE,
    attribute22                   ic_lots_mst.attribute22%TYPE,
    attribute21                   ic_lots_mst.attribute21%TYPE,
    attribute23                   ic_lots_mst.attribute23%TYPE,
    attribute24                   ic_lots_mst.attribute24%TYPE,
    attribute25                   ic_lots_mst.attribute25%TYPE,
    attribute26                   ic_lots_mst.attribute26%TYPE,
    attribute27                   ic_lots_mst.attribute27%TYPE,
    attribute28                   ic_lots_mst.attribute28%TYPE,
    attribute29                   ic_lots_mst.attribute29%TYPE,
    attribute30                   ic_lots_mst.attribute30%TYPE,
    attribute_category            ic_lots_mst.attribute_category%TYPE,
    odm_lot_number                ic_lots_mst.odm_lot_number%TYPE
  );
--
-- Ver_1.6 E_�{�ғ�_15887 ADD End
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- Message�擾
  FUNCTION get_msg(
    iv_application   IN VARCHAR2,
    iv_name          IN VARCHAR2,
    iv_token_name1   IN VARCHAR2 DEFAULT NULL,
    iv_token_value1  IN VARCHAR2 DEFAULT NULL,
    iv_token_name2   IN VARCHAR2 DEFAULT NULL,
    iv_token_value2  IN VARCHAR2 DEFAULT NULL,
    iv_token_name3   IN VARCHAR2 DEFAULT NULL,
    iv_token_value3  IN VARCHAR2 DEFAULT NULL,
    iv_token_name4   IN VARCHAR2 DEFAULT NULL,
    iv_token_value4  IN VARCHAR2 DEFAULT NULL,
    iv_token_name5   IN VARCHAR2 DEFAULT NULL,
    iv_token_value5  IN VARCHAR2 DEFAULT NULL,
    iv_token_name6   IN VARCHAR2 DEFAULT NULL,
    iv_token_value6  IN VARCHAR2 DEFAULT NULL,
    iv_token_name7   IN VARCHAR2 DEFAULT NULL,
    iv_token_value7  IN VARCHAR2 DEFAULT NULL,
    iv_token_name8   IN VARCHAR2 DEFAULT NULL,
    iv_token_value8  IN VARCHAR2 DEFAULT NULL,
    iv_token_name9   IN VARCHAR2 DEFAULT NULL,
    iv_token_value9  IN VARCHAR2 DEFAULT NULL,
    iv_token_name10  IN VARCHAR2 DEFAULT NULL,
    iv_token_value10 IN VARCHAR2 DEFAULT NULL,
--  2008/10/29 v1.4 T.Yoshimoto Add Start ����#251
    iv_token_name11  IN VARCHAR2 DEFAULT NULL,
    iv_token_value11 IN VARCHAR2 DEFAULT NULL
--  2008/10/29 v1.4 T.Yoshimoto Add End ����#251
    )
    RETURN VARCHAR2;
--
  -- �S���Җ��擾
  FUNCTION get_user_name
    (
      in_user_id    IN FND_USER.USER_ID%TYPE -- ���[�UID
    )
    RETURN VARCHAR2 ;                        -- �S���Җ�
--
  -- �S���������擾
  FUNCTION get_user_dept
    (
      in_user_id    IN FND_USER.USER_ID%TYPE -- ���[�UID
    )
    RETURN VARCHAR2 ;                        -- �S��������
--
  -- �e�[�u�����b�N�֐�
  FUNCTION get_tbl_lock(
    iv_schema_name IN VARCHAR2,         -- �X�L�[�}��
    iv_table_name  IN VARCHAR2)         -- �e�[�u����
    RETURN BOOLEAN;                     -- TRUE:���b�N����,FALSE:���b�N���s
--
 -- �e�[�u���f�[�^�ꊇ�폜�֐�
  FUNCTION del_all_data(
    iv_schema_name IN VARCHAR2,         -- �X�L�[�}��
    iv_table_name  IN VARCHAR2)         -- �e�[�u����
    RETURN BOOLEAN;                     -- TRUE:�ꊇ�폜����,FALSE:�ꊇ�폜���s
--
  -- OPM�݌ɉ�v����CLOSE�N���擾�֐�
  FUNCTION get_opminv_close_period RETURN VARCHAR2; -- CLSE�N��YYYYMM
--
  -- �J�e�S���擾�֐�
  FUNCTION get_category_desc(
    in_item_no      IN  VARCHAR2,     -- �i��
    iv_category_set IN  VARCHAR2)     -- �J�e�S���Z�b�g�R�[�h
    RETURN VARCHAR2;                  -- �J�e�S���E�v
--
  -- �ɓ������ǍH����擾�v���V�[�W��
  PROCEDURE get_sagara_factory_info(
    ov_postal_code OUT NOCOPY VARCHAR2,     -- �X�֔ԍ�
    ov_address     OUT NOCOPY VARCHAR2,     -- �Z��
    ov_tel_num     OUT NOCOPY VARCHAR2,     -- �d�b�ԍ�
    ov_fax_num     OUT NOCOPY VARCHAR2,     -- FAX�ԍ�
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �J�����_�R�[�h�擾�֐�
  FUNCTION get_calender_cd(
    iv_whse_code      IN  VARCHAR2 DEFAULT NULL,  -- �ۊǑq�ɃR�[�h
    in_party_site_no  IN  VARCHAR2 DEFAULT NULL,  -- �p�[�e�B�T�C�g�ԍ�
    iv_leaf_drink     IN  VARCHAR2)               -- ���[�t�h�����N�敪
    RETURN VARCHAR2;
--
  -- �ғ����`�F�b�N�֐�
  FUNCTION check_oprtn_day(
    id_date         IN  DATE,      -- �`�F�b�N�Ώۓ��t
    iv_calender_cd  IN  VARCHAR2)  -- �J�����_�[�R�[�h
    RETURN NUMBER;
--
  -- �̔Ԋ֐�
  PROCEDURE get_seq_no(
    iv_seq_class  IN  VARCHAR2,     --   �̔Ԃ���ԍ���\���敪
    ov_seq_no     OUT NOCOPY VARCHAR2,     --   �̔Ԃ����Œ蒷12���̔ԍ�
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �������擾�v���V�[�W��
  PROCEDURE get_dept_info(
    iv_dept_cd          IN  VARCHAR2,          -- �����R�[�h(���Ə�CD)
    id_appl_date        IN  DATE DEFAULT NULL, -- ���
    ov_postal_code      OUT NOCOPY VARCHAR2,          -- �X�֔ԍ�
    ov_address          OUT NOCOPY VARCHAR2,          -- �Z��
    ov_tel_num          OUT NOCOPY VARCHAR2,          -- �d�b�ԍ�
    ov_fax_num          OUT NOCOPY VARCHAR2,          -- FAX�ԍ�
    ov_dept_formal_name OUT NOCOPY VARCHAR2,          -- ����������
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �x�����������擾�֐�
  FUNCTION get_term_of_payment(
    in_vendor_id   IN NUMBER,             -- �d����ID
    id_appl_date   IN DATE DEFAULT NULL)  -- �L�����t
    RETURN VARCHAR2;                      -- �x����������
--
  -- �p�����[�^�`�F�b�N�F���t�`���iYYYYMM�j
  FUNCTION check_param_date_yyyymm(
    iv_date_ym      IN VARCHAR2)          -- �`�F�b�N�Ώۓ��t
    RETURN NUMBER;                        -- 0:���t,1:�G���[
--
  -- �p�����[�^�`�F�b�N�F���t�`��(YYYYMMDD HH24:MI:SS)
  FUNCTION check_param_date_yyyymmdd(
    iv_date_ymd      IN VARCHAR2)         -- �`�F�b�N�Ώۓ��t
    RETURN NUMBER;                        -- 0:���t,1:�G���[
--
  -- �W��API���O�o��API
  PROCEDURE put_api_log(
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �A�E�g�o�E���h�������擾�֐�
  PROCEDURE get_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    or_outbound_rec     OUT NOCOPY outbound_rec,      -- �t�@�C�����
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--  �t�@�C���o�͏��X�V�֐�
  PROCEDURE upd_outbound_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    id_last_update_date IN  DATE,                     -- �t�@�C���ŏI�X�V��
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--  ���[�N�t���[�N���֐�
  PROCEDURE wf_start(
    iv_wf_ope_div       IN  VARCHAR2,                 -- �����敪
    iv_wf_class         IN  VARCHAR2,                 -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,                 -- ����
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �������\���Z�oAPI
  FUNCTION get_can_enc_total_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER;                                    -- �������\��
--
  -- �L�����x�[�X�����\���Z�oAPI
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER;                                    -- �����\��
--
  -- �莝�݌ɐ��ʎZ�oAPI
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER;                                    -- �莝�݌ɐ���
--
  -- �����\���Z�oAPI
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER;                                    -- �����\��
--
  -- ���o�Ɋ��Z�֐�(���Y�o�b�`�p)
  FUNCTION rcv_ship_conv_qty(
    iv_conv_type  IN VARCHAR2,          -- �ϊ����@(1:���o�Ɋ��Z�P�ʁ���1�P��,2:���̋t)
    in_item_id    IN NUMBER,            -- OPM�i��ID
    in_qty        IN NUMBER)            -- �ϊ��Ώۂ̐���
    RETURN NUMBER;                      -- �ϊ����ʂ̐���
--
  -- �S������CD�擾
  FUNCTION get_user_dept_code
    (
      in_user_id    IN FND_USER.USER_ID%TYPE, -- ���[�UID
      id_appl_date  IN DATE DEFAULT NULL      -- ���
    )
    RETURN VARCHAR2 ;                        -- �S��������
--
-- Ver_1.6 E_�{�ғ�_15887 ADD Start
--  ���b�g�}�X�^�����쐬�֐�
  PROCEDURE create_lot_mst_history(
    ir_lot_data         IN  lot_rec,                  -- �X�V�O���b�g�}�X�^�̃f�[�^
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- Ver_1.6 E_�{�ғ�_15887 ADD End
END xxcmn_common_pkg;
/
