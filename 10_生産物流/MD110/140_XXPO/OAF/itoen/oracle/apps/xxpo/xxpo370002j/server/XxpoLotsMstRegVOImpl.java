/*============================================================================
* ファイル名 : XxpoLotsMstRegVOImpl
* 概要説明   : 検査ロット登録情報ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 検査ロット登録情報ビューオブジェクトクラスです。
 * @author  ORACLE 戸谷田 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoLotsMstRegVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoLotsMstRegVOImpl()
  {
  }
  
  /**
   * 初期化メソッド。
   * @param lotId ロットID
   */
  public void initQuery(Number lotId)
  {
    setWhereClauseParams(null);
    setWhereClauseParam(0, lotId);
    executeQuery();
  }

}