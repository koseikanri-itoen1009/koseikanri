CREATE OR REPLACE VIEW XXCSM_MST_QUALIFICATE_PNT_V
(
  row_id
 ,subject_year
 ,post_cd
 ,post_name
 ,qualificate_cd
 ,qualificate_name
 ,duties_cd
 ,duties_name
 ,qualificate_point
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
 ,request_id
 ,program_application_id
 ,program_id
 ,program_update_date
)
AS
SELECT xmqp.rowid
      ,xmqp.subject_year
      ,xmqp.post_cd
      ,xmqp.post_cd ||'_'|| xlnlv.base_name AS base_name  -- �����R�[�h�ƕ��������������A�������Ƃ��Ď擾����
      ,xmqp.qualificate_cd
      ,(SELECT xqlv.qualificate_cd ||'_'|| xqlv.qualificate_name  AS qualificate_name
        FROM   xxcsm_qualificate_list_v  xqlv
        WHERE  xqlv.qualificate_cd = xmqp.qualificate_cd
        AND    ROWNUM = 1)  -- ���i�R�[�h�̏d���Ή��B�ŏ��Ɏ擾�������i�R�[�h�Ǝ��i�����������A���i���Ƃ��Ď擾����
      ,xmqp.duties_cd
      ,(SELECT xdlv.duties_cd ||'_'|| xdlv.duties_name  AS  duties_name
        FROM   xxcsm_duties_list_v       xdlv
        WHERE  xmqp.duties_cd  = xdlv.duties_cd
        AND    ROWNUM = 1)  -- �E���R�[�h�̏d���Ή��B�ŏ��Ɏ擾�����E���R�[�h�ƐE�������������A�E�����Ƃ��Ď擾����
      ,xmqp.qualificate_point
      ,xmqp.created_by
      ,xmqp.creation_date
      ,xmqp.last_updated_by
      ,xmqp.last_update_date
      ,xmqp.last_update_login
      ,xmqp.request_id
      ,xmqp.program_application_id
      ,xmqp.program_id
      ,xmqp.program_update_date
FROM  xxcsm_mst_qualificate_pnt xmqp
     ,xxcsm_loc_name_list_v     xlnlv
WHERE xmqp.post_cd        = xlnlv.base_code
;
--
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.row_id                  IS '�q�n�v�Q�h�c';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.subject_year            IS '�Ώ۔N�x';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.post_cd                 IS '�����R�[�h';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.post_name               IS '������';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_cd          IS '���i�R�[�h';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_name        IS '���i��';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.duties_cd               IS '�E���R�[�h';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.duties_name             IS '�E����';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_point       IS '���i�|�C���g';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.created_by              IS '�쐬��';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.creation_date           IS '�쐬��';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_updated_by         IS '�ŏI�X�V��';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_update_date        IS '�ŏI�X�V��';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_update_login       IS '�ŏI�X�V���O�C��ID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.request_id              IS '�v��ID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_application_id  IS '�v���O�����A�v���P�[�V����ID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_id              IS '�v���O����ID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_update_date     IS '�v���O�����X�V��';
--
COMMENT ON TABLE  xxcsm_mst_qualificate_pnt_v IS '���i�|�C���g�}�X�^�r���[';
