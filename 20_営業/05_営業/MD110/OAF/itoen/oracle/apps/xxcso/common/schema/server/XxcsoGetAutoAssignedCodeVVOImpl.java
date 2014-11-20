/*============================================================================
* ファイル名 : XxcsoGetAutoAssignedCodeVVOImpl
* 概要説明   : 自動採番コード取得ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 自動採番されたコードを取得するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoGetAutoAssignedCodeVVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoGetAutoAssignedCodeVVOImpl()
  {
  }

  public void initQuery(
    String assignClass
   ,String baseCode
   ,Date   currentDate
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, assignClass);
    setWhereClauseParam(1, baseCode);
    setWhereClauseParam(2, currentDate);

    executeQuery();
  }
}