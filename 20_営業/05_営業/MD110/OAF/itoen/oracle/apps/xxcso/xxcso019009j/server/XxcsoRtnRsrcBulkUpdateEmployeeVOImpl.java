/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateEmployeeVOImpl
* 概要説明   : 拠点内担当営業員ビュークラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基    新規作成
* 2010-03-23 1.1  SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2010-03-23 [E_本稼動_01942] Add Start
import oracle.jbo.domain.Date;
// 2010-03-23 [E_本稼動_01942] Add End

/*******************************************************************************
 * 拠点内担当営業員のビュークラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateEmployeeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param employeeNumber       従業員番号
   * @param baseCodeDate         対象拠点日付
   * @param baseCode             拠点コード
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
// 2010-03-23 [E_本稼動_01942] Add Start
   ,Date   baseCodeDate
// 2010-03-23 [E_本稼動_01942] Add End
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
// 2010-03-23 [E_本稼動_01942] Add Start
    //setWhereClauseParam(1, baseCode);
    setWhereClauseParam(1, baseCodeDate);
// 2010-03-23 [E_本稼動_01942] Add End
    setWhereClauseParam(2, baseCode);

    executeQuery();
  }
}