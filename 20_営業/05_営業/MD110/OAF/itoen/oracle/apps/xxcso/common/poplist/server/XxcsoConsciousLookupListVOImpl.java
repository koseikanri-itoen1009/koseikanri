/*============================================================================
* ファイル名 : XxcsoLookupListVOImpl
* 概要説明   : クイックコードポップリスト用ビュークラス
*             APPLICATION_IDやVIEW_APPLICATION_IDを意識したポップリスト用です。
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS小川浩    新規作成
* 2008-12-16 1.0  SCS小川浩    LOOKUP_TYPEのみで取得するように修正
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.poplist.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * クイックコードから表示するポップリストのビュークラスです。
 * APPLICATION_IDやVIEW_APPLICATION_IDを意識したポップリスト用です。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoConsciousLookupListVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoConsciousLookupListVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param appShortName     アプリケーション短縮名（アプリケーション）
   * @param viewAppShortName アプリケーション短縮名（表示）
   * @param lookupType       ルックアップタイプ
   * @param whereStmt        検索条件
   * @param orderBy          ソート条件
   *****************************************************************************
   */
  public void initQuery(
    String appShortName,
    String viewAppShortName,
    String lookupType,
    String whereStmt,
    String orderBy
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, appShortName);
    setWhereClauseParam(index++, viewAppShortName);
    setWhereClauseParam(index++, lookupType);

    setWhereClause(whereStmt);
    setOrderByClause(orderBy);
  }
}