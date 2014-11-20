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
      ,xmqp.post_cd ||'_'|| xlnlv.base_name AS base_name  -- 部署コードと部署名を結合し、部署名として取得する
      ,xmqp.qualificate_cd
      ,(SELECT xqlv.qualificate_cd ||'_'|| xqlv.qualificate_name  AS qualificate_name
        FROM   xxcsm_qualificate_list_v  xqlv
        WHERE  xqlv.qualificate_cd = xmqp.qualificate_cd
        AND    ROWNUM = 1)  -- 資格コードの重複対応。最初に取得した資格コードと資格名を結合し、資格名として取得する
      ,xmqp.duties_cd
      ,(SELECT xdlv.duties_cd ||'_'|| xdlv.duties_name  AS  duties_name
        FROM   xxcsm_duties_list_v       xdlv
        WHERE  xmqp.duties_cd  = xdlv.duties_cd
        AND    ROWNUM = 1)  -- 職務コードの重複対応。最初に取得した職務コードと職務名を結合し、職務名として取得する
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
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.row_id                  IS 'ＲＯＷ＿ＩＤ';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.subject_year            IS '対象年度';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.post_cd                 IS '部署コード';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.post_name               IS '部署名';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_cd          IS '資格コード';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_name        IS '資格名';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.duties_cd               IS '職務コード';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.duties_name             IS '職務名';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.qualificate_point       IS '資格ポイント';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.created_by              IS '作成者';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.creation_date           IS '作成日';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_updated_by         IS '最終更新者';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_update_date        IS '最終更新日';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.last_update_login       IS '最終更新ログインID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.request_id              IS '要求ID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_application_id  IS 'プログラムアプリケーションID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_id              IS 'プログラムID';
COMMENT ON COLUMN xxcsm_mst_qualificate_pnt_v.program_update_date     IS 'プログラム更新日';
--
COMMENT ON TABLE  xxcsm_mst_qualificate_pnt_v IS '資格ポイントマスタビュー';
