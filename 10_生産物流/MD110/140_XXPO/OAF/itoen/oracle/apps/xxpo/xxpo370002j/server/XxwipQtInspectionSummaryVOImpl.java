/*============================================================================
* ファイル名 : XxwipQtInspectionSummaryVOImpl
* 概要説明   : 品質検査依頼情報ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田大輔     新規作成
* 2008-05-09 1.1  熊本 和郎      内部変更要求#28,41,43対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 品質検査依頼情報ビューオブジェクトクラスです。
 * @author  ORACLE 戸谷田 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxwipQtInspectionSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipQtInspectionSummaryVOImpl()
  {
  }

  /**
   * 初期化メソッド。
   * @param insReqNo 品質検査依頼No
   */
// mod start 1.1
//  public void initQuery(Number insReqNo)
  public void initQuery(String insReqNo)
// mod end 1.1
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, insReqNo);
    executeQuery();
  }

}