/*============================================================================
* ファイル名 : XxcsoSpDecisionSearchInitVOImpl
* 概要説明   : SP専決書検索画面初期値用ビュークラス
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

/*******************************************************************************
 * SP専決書検索画面の初期値を設定するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchInitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchInitVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param searchClass 検索区分
   *****************************************************************************
   */
  public void initQuery(
    String searchClass
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);
    setWhereClauseParam(index++, searchClass);

    executeQuery();
  }
}