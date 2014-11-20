/*============================================================================
* ファイル名 : XxcsoSpDecisionBmFormatVOImpl
* 概要説明   : BMの項目サイズ設定用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-03-05 1.0   SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * BM情報のサイズを設定するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionBmFormatVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionBmFormatVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param vendorName      送付先名
   * @param vendorNameAlt   送付先名（カナ）
   * @param state           都道府県
   * @param city            市・区
   * @param address1        住所１
   * @param address2        住所２
   *****************************************************************************
   */
  public void initQuery(
    String  vendorName
   ,String  vendorNameAlt
   ,String  state
   ,String  city
   ,String  address1
   ,String  address2
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, vendorName);
    setWhereClauseParam(1, vendorNameAlt);
    setWhereClauseParam(2, state);
    setWhereClauseParam(3, city);
    setWhereClauseParam(4, address1);
    setWhereClauseParam(5, address2);

    executeQuery();
  }
}