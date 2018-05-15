/*************************************************************************
 * 
 * VIEW Name       : XXCSO_ROUTE_MANAGEMENT_EMP_V
 * Description     : ルート管理用営業員セキュリティビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2018/02/15    1.0   K.Kiriu      初回作成(E_本稼動_14722)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_route_management_emp_v(
  employee_number
 ,employee_name
 ,employee_base_code
)
AS
SELECT  xrv2.employee_number  employee_number
       ,xrv2.full_name        employee_name
       ,jrgmo.rsg_dept_code   employee_base_code
FROM    xxcso_resources_v2  xrv2
       ,( SELECT  jrgb.group_id        group_id
                 ,jrgb.attribute1      rsg_dept_code
                 ,jrgm.group_member_id group_member_id
                 ,jrgm.resource_id     resource_id
          FROM    jtf_rs_groups_b      jrgb
                 ,jtf_rs_group_members jrgm
          WHERE   NVL( jrgb.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
          AND     jrgm.delete_flag = 'N'
          AND     jrgm.group_id    = jrgb.group_id
        )                   jrgmo
WHERE   xrv2.resource_id = jrgmo.resource_id
AND     (
          (
            jrgmo.rsg_dept_code = xxcso_util_common_pkg.get_rs_base_code(
                                    jrgmo.resource_id
                                   ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                  )
          )
          OR
          (
            jrgmo.rsg_dept_code = xxcso_util_common_pkg.get_rs_base_code(
                                   jrgmo.resource_id
                                  ,TRUNC(ADD_MONTHS(xxcso_util_common_pkg.get_online_sysdate, 1), 'MM')
                                 )
          )
        )
/
COMMENT ON COLUMN xxcso_route_management_emp_v.employee_number      IS '営業員';
COMMENT ON COLUMN xxcso_route_management_emp_v.employee_name        IS '営業員名';
COMMENT ON COLUMN xxcso_route_management_emp_v.employee_base_code   IS '所属拠点';
COMMENT ON TABLE xxcso_route_management_emp_v                       IS 'ルート管理用営業員セキュリティビュー';
