/*============================================================================
* ファイル名 : XxcsoSpDecisionSummaryVOImpl
* 概要説明   : SP専決書検索結果用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0   SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * SP専決書検索画面の検索結果を取得するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param searchClass      検索区分
   * @param applyBaseCode    申請拠点コード
   * @param applyUserCode    申請者コード
   * @param applyDateStart   申請日（開始）
   * @param applyDateEnd     申請日（終了）
   * @param status           ステータス
   * @param spDecisionNumber SP専決番号
   * @param custAccountId    アカウントID
   *****************************************************************************
   */
  public void initQuery(
    String searchClass
   ,String applyBaseCode
   ,String applyUserCode
   ,Date   applyDateStart
   ,Date   applyDateEnd
   ,String status
   ,String spDecisionNumber
   ,Number custAccountId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, applyBaseCode);
    setWhereClauseParam(index++, applyUserCode);
    setWhereClauseParam(index++, applyDateStart);
    setWhereClauseParam(index++, applyDateEnd);
    setWhereClauseParam(index++, status);
    setWhereClauseParam(index++, spDecisionNumber);
    setWhereClauseParam(index++, custAccountId);

    executeQuery();
  }
}